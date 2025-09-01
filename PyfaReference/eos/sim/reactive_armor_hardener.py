# ==============================================================================
# Copyright (C) 2011 Diego Duclos
# Copyright (C) 2011-2018 Anton Vorobyov
#
# This file is part of Eos.
#
# Eos is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Eos is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Eos. If not, see <http://www.gnu.org/licenses/>.
# ==============================================================================


import math
from copy import copy
from logging import getLogger

from eos.const.eve import AttrId
from eos.const.eve import EffectId
from eos.pubsub.message import AttrsValueChanged
from eos.pubsub.message import AttrsValueChangedMasked
from eos.pubsub.message import EffectsStarted
from eos.pubsub.message import EffectsStopped
from eos.pubsub.message import RahIncomingDmgChanged
from eos.pubsub.subscriber import BaseSubscriber
from eos.util.repr import make_repr_str
from eos.util.round import sig_round


logger = getLogger(__name__)


MAX_SIMULATION_TICKS = 500
SIG_DIGITS = 10
# List all armor resonance attributes and also define default sorting order.
# When equal damage is received across several damage types, those which come
# earlier in this list will be picked as donors
res_attr_ids = (
    AttrId.armor_em_dmg_resonance,
    AttrId.armor_expl_dmg_resonance,
    AttrId.armor_kin_dmg_resonance,
    AttrId.armor_therm_dmg_resonance)
# Format: {resonance attribute: damage profile field}
attr_profile_map = {
    AttrId.armor_em_dmg_resonance: 'em',
    AttrId.armor_therm_dmg_resonance: 'thermal',
    AttrId.armor_kin_dmg_resonance: 'kinetic',
    AttrId.armor_expl_dmg_resonance: 'explosive'}


class RahState:
    """Represents state of one RAH for single simulation tick.

    Attributes:
        item: RAH item.
        cycling: How much time passed for this RAH since start of its cycle
            until this moment.
        resos: current resonances of RAH in {resonance attribute ID: resonance
            attribute value} form.
    """

    def __init__(self, item, cycling, resos):
        self.item = item
        self.cycling = cycling
        self.resos = resos
        self._rounded_resos = {
            attr_id: sig_round(value, SIG_DIGITS)
            for attr_id, value in resos.items()}

    # Use rounded resonances for more reliable loop detection, as without it
    # accumulated float errors may lead to failed loop detection, in case float
    # values are really close, but still different
    def __hash__(self):
        return hash((
            id(self.item),
            self.cycling,
            frozenset(self._rounded_resos.items())))

    def __eq__(self, other):
        return all((
            self.item is other.item,
            self.cycling == other.cycling,
            self._rounded_resos == other._rounded_resos))

    def __repr__(self):
        spec = ['item', 'cycling', 'resos']
        return make_repr_str(self, spec)


class ReactiveArmorHardenerSimulator(BaseSubscriber):
    """Adapts RAH's stats to incoming damage profile.

    It works by installing callbacks as RAH resistance attribute overrides.
    When any of these attributes is requested, simulator is run. Upon
    completion, all values are stored for future use. When anything which may
    change RAH resistances changes, stored result is removed, so that upon
    next access they can be calculated again.
    """

    def __init__(self, fit):
        # Contains all known RAHs and results of simulation
        # Format: {RAH item: {resonance attribute ID: resonance attribute
        # value}}
        self.__data = {}
        self.__fit = fit
        self.__running = False
        fit._subscribe(self, self._handler_map.keys())

    def get_reso(self, item, attr_id):
        """Get specified resonance for specified RAH item."""
        # Try fetching already simulated results
        resos = self.__data[item]
        try:
            reso = resos[attr_id]
        # If no results are readily available, run simulatiomn
        except KeyError:
            self.__running = True
            try:
                self._run_simulation()
            except KeyboardInterrupt:
                raise
            # In case of any errors, use unsimulated RAH attributes
            except Exception:
                msg = 'unexpected exception, setting unsimulated resonances'
                logger.warning(msg)
                self.__set_unsimulated_resos()
                reso = self.__data[item][attr_id]
            # Fetch requested resonance after successful simulation
            else:
                reso = self.__data[item][attr_id]
            # Send notifications and do cleanup regardless of simulation success
            finally:
                # Even though caller requested specific resonance of specific
                # RAH, we've calculated all resonances for all RAHs, thus we
                # need to send notifications about all calculated values
                for item in self.__data:
                    for attr_id in res_attr_ids:
                        item.attrs._override_value_may_change(attr_id)
                self.__running = False
        return reso

    def _run_simulation(self):
        """Controls flow of actual RAH simulation."""
        # Put unsimulated resonances into container for results
        self.__set_unsimulated_resos()

        # If there's no ship, simulation is meaningless - keep unsimulated
        # results
        ship = self.__fit.ship
        if ship is None or not ship._is_loaded:
            return

        # Containers for tick state history. We need history to detect loops,
        # which helps to receive more accurate resonances and do it faster in
        # majority of the cases.
        # List contains actual history
        # Format: [frozenset(RAH history entries), ...]
        tick_history = []
        # We also have set with historical entries for fast membership check
        # Format: {frozenset(RAH history entries), ...}
        ticks_seen = set()

        # Use RAH incoming damage profile if available, if it's not set - fall
        # back to default profile
        if self.__fit.rah_incoming_dmg is not None:
            incoming_dmg = self.__fit.rah_incoming_dmg
        else:
            incoming_dmg = self.__fit.default_incoming_dmg

        # Container for damage each RAH received during its cycle. May
        # span across several simulation ticks for multi-RAH setups
        # Format: {RAH item: {resonance attribute: damage received}}
        cycle_dmg_data = {
            item: {attr_id: 0 for attr_id in res_attr_ids}
            for item in self.__data}
        ship_attrs = ship.attrs

        for tick_data in self.__sim_tick_iter(MAX_SIMULATION_TICKS):
            time_passed, cycled, cycling_data = tick_data
            # For each RAH, calculate damage received during this tick and add
            # it to damage received during RAH cycle
            for item, item_cycle_dmg in cycle_dmg_data.items():
                for attr_id in res_attr_ids:
                    item_cycle_dmg[attr_id] += (
                        getattr(incoming_dmg, attr_profile_map[attr_id]) *
                        ship_attrs[attr_id] * time_passed)

            for item in cycled:
                # If RAH just finished its cycle, make resist switch - get new
                # resonances
                new_resos = self.__get_next_resos(
                    self.__data[item], cycle_dmg_data[item],
                    item.attrs[AttrId.resist_shift_amount] / 100)

                # Then write these resonances to dictionary with results and
                # notify everyone about these changes. This is needed to get
                # updated ship resonances next tick
                self.__data[item].update(new_resos)
                for attr_id in res_attr_ids:
                    item.attrs._override_value_may_change(attr_id)

                # Reset damage counter for RAH which completed its cycle
                for attr_id in res_attr_ids:
                    cycle_dmg_data[item][attr_id] = 0

            # Record current tick state
            tick_state = frozenset(
                # Copy resonances, as we will be modifying them each tick
                RahState(item, cycling_data[item], copy(resos))
                for item, resos in self.__data.items())

            # See if we're in a loop, if we are - calculate average resists
            # across tick states which are within the loop
            if tick_state in ticks_seen:
                tick_states_loop = tick_history[tick_history.index(tick_state):]
                avg_resos = self.__get_avg_resos(tick_states_loop)
                for item, resos in avg_resos.items():
                    self.__data[item] = resos
                return

            # Update history only if we don't have such entries
            ticks_seen.add(tick_state)
            tick_history.append(tick_state)

        # If we didn't find any RAH state loops during specified quantity of sim
        # ticks, calculate average resonances based on whole history, excluding
        # initial adaptation period
        else:
            ticks_to_ignore = min(
                self.__estimate_initial_adaptation_ticks(tick_history),
                # Never ignore more than half of the history
                math.floor(len(tick_history) / 2))

            avg_resos = self.__get_avg_resos(tick_history[ticks_to_ignore:])
            for item, resos in avg_resos.items():
                self.__data[item] = resos
            return

    def __set_unsimulated_resos(self):
        """Put unsimulated resonance values into results.

        Unsimulated resonance values are values which are modified by other
        items, but not modified by overrides from this simulator.
        """
        for item, resos in self.__data.items():
            for attr_id in res_attr_ids:
                resos[attr_id] = item.attrs._get_without_overrides(attr_id)

    def __sim_tick_iter(self, max_ticks):
        """Iterate over simulation ticks.

        Ticks are points in time when cycle of any RAH is finished.

        Args:
            max_ticks: Limit quantity of ticks produced.

        Yields:
            Tick data in the form of tuple of (time passed since last tick, list
            of RAHs finished cycling, map with info on how long each RAH has
            been in current cycle) format.
        """
        if max_ticks < 1:
            return
        # Keep track of RAH cycle data in this map
        # Format: {RAH item: current cycle time}
        iter_cycle_data = {item: 0 for item in self.__data}
        # Always copy cycle data map to make sure it's not getting modified from
        # outside, which may alter iter state
        yield 0, (), copy(iter_cycle_data)
        # We've already yielded 1 value
        tick = 1
        while True:
            # Stop iteration when current tick exceedes limit
            tick += 1
            if tick > max_ticks:
                return
            # Pick time remaining until some RAH finishes its cycle
            time_passed = min(
                self.__get_rah_duration(item) - cycling
                for item, cycling in iter_cycle_data.items())
            # Compose set of RAHs which will finish cycle after passed amount of
            # time
            cycled = set()
            for item, cycling in iter_cycle_data.items():
                # Have time tolerance to cancel float calculation errors. It's
                # needed for multi-RAH configurations, e.g. when normal RAH does
                # 17 cycles, heated one does 20, but
                # >>> sum([0.85] * 20) == 17
                # False
                if (
                    sig_round(cycling + time_passed, SIG_DIGITS) ==
                    sig_round(self.__get_rah_duration(item), SIG_DIGITS)
                ):
                    cycled.add(item)
            # Update map which tracks RAHs' cycle states
            for item in iter_cycle_data:
                if item in cycled:
                    iter_cycle_data[item] = 0
                else:
                    iter_cycle_data[item] += time_passed
            yield time_passed, cycled, copy(iter_cycle_data)

    def __get_next_resos(self, current_resos, received_dmg, shift_amt):
        """Calculate new resonances RAH should take on the next cycle.

        Args:
            current_resos: Current RAH resonances in {resonance attribute ID:
                resonance attribute value} format.
            received_dmg: Damage received by RAH during current cycle.
            shift_amt: Max allowed value of resonance attribute value it can
                take from donor resonances.

        Returns:
            New RAH resonances in {resonance attribute ID: resonance attribute
            value} format.
        """
        # We borrow resistances from at least 2 resist types, possibly more if
        # ship didn't take damage of these types
        donors = max(2, len([
            item
            for item in received_dmg
            if received_dmg[item] == 0]))
        recipients = 4 - donors
        # Primary key for sorting is received damage, secondary is default
        # order. Default order "sorting" happens due to default order of
        # attributes and stable sorting against primary key.
        sorted_reso_attr_ids = sorted(res_attr_ids, key=received_dmg.get)
        donated_amt = 0
        new_resos = {}
        # Donate
        for reso_attr_id in sorted_reso_attr_ids[:donors]:
            current_reso = current_resos[reso_attr_id]
            # Can't borrow more than it has
            to_donate = min(1 - current_reso, shift_amt)
            donated_amt += to_donate
            new_resos[reso_attr_id] = current_reso + to_donate
        # Take
        for reso_attr_id in sorted_reso_attr_ids[donors:]:
            current_reso = current_resos[reso_attr_id]
            new_resos[reso_attr_id] = current_reso - donated_amt / recipients
        return new_resos

    def __get_avg_resos(self, tick_states):
        """Calculate average resonances for RAHs.

        Args:
            tick_states: Iterable with tick states, where each tick state is
                iterable of RAH states.

        Returns:
            Average resonance values in {RAH item: averaged resonances} format.
        """
        # Container for resonances each RAH used
        # Format: {RAH item: [resonance maps]}
        rahs_resos_used = {}
        for tick_state in tick_states:
            for rah_state in tick_state:
                # Add resonances to container only when RAH cycle is just
                # starting
                if rah_state.cycling != 0:
                    continue
                rah_resos_used = rahs_resos_used.setdefault(rah_state.item, [])
                rah_resos_used.append(rah_state.resos)
        # Calculate average values
        avg_resos = {}
        for item, resos in rahs_resos_used.items():
            avg_resos[item] = {
                attr_id: sum(r[attr_id] for r in resos) / len(resos)
                for attr_id in res_attr_ids}
        return avg_resos

    def __estimate_initial_adaptation_ticks(self, tick_states):
        """Estimate how much time RAH takes for initial adaptation.

        Pick RAH which has the slowest adaptation and guesstimate its
        approximate adaptation period in ticks for the worst-case.
        """
        # Get max amount of time it takes to exhaust the highest resistance of
        # each RAH
        # Format: {RAH item: quantity of cycles}
        exhaustion_cycles = {}
        for item in self.__data:
            # Calculate how many cycles it would take for highest resistance
            # (lowest resonance) to be exhausted
            exhaustion_cycles[item] = max(math.ceil(
                (1 - item.attrs._get_without_overrides(attr_id)) /
                (item.attrs[AttrId.resist_shift_amount] / 100)
            ) for attr_id in res_attr_ids)
        # Slowest RAH is the one which takes the most time to exhaust its
        # highest resistance when it's used strictly as donor
        slowest_item = max(
            self.__data,
            key=lambda i: exhaustion_cycles[i] * self.__get_rah_duration(i))
        # Multiply quantity of resistance exhaustion cycles by 1.5, to give RAH
        # more time for 'finer' adjustments
        slowest_cycles = math.ceil(exhaustion_cycles[slowest_item] * 1.5)
        if slowest_cycles == 0:
            return 0
        # We rely on cycling time attribute to be zero in order to determine
        # that cycle for the slowest RAH has just ended. It is zero for the very
        # first tick in the history too, thus we skip it, but take it into
        # initial tick count
        ignored_tick_count = 1
        tick_count = ignored_tick_count
        cycle_count = 0
        for tick_state in tick_states[ignored_tick_count:]:
            # Once slowest RAH finished last cycle, do not count this tick and
            # break the loop
            for item_state in tick_state:
                if item_state.item is slowest_item:
                    if item_state.cycling == 0:
                        cycle_count += 1
                    break
            if cycle_count >= slowest_cycles:
                break
            tick_count += 1
        return tick_count

    # Message handling
    def _handle_effects_started(self, msg):
        if EffectId.adaptive_armor_hardener in msg.effect_ids:
            for attr_id in res_attr_ids:
                msg.item.attrs._set_override_callback(
                    attr_id, (self.get_reso, (msg.item, attr_id), {}))
            self.__data.setdefault(msg.item, {})
            self.__clear_results()

    def _handle_effects_stopped(self, msg):
        if EffectId.adaptive_armor_hardener in msg.effect_ids:
            for attr_id in res_attr_ids:
                msg.item.attrs._del_override_callback(attr_id)
            try:
                del self.__data[msg.item]
            except KeyError:
                pass
            self.__clear_results()

    def _handle_attr_changed(self, msg):
        attr_changes = msg.attr_changes
        ship = self.__fit.ship
        # Ship resistances
        if (
            ship in attr_changes and
            attr_changes[ship].intersection(res_attr_ids)
        ):
            self.__clear_results()
            return
        # RAH resistance shift or cycle time
        for item in set(self.__data).intersection(attr_changes):
            changed_attr_ids = attr_changes[item]
            if (
                AttrId.resist_shift_amount in changed_attr_ids or (
                    # Cycle time change invalidates results only when there're
                    # more than 1 RAHs
                    len(self.__data) > 1 and
                    self.__get_rah_effect(item).duration_attr_id in
                    changed_attr_ids)
            ):
                self.__clear_results()
                return

    def _handle_attr_changed_masked(self, msg):
        # We've set up overrides on RAHs' resonance attributes, but when base
        # (not modified by simulator) values of these attributes change, we
        # should re-run simulator - as now we have different resonance value to
        # base sim results off
        attr_changes = msg.attr_changes
        for item in set(self.__data).intersection(attr_changes):
            if attr_changes[item].intersection(res_attr_ids):
                self.__clear_results()
                return

    def _handle_changed_dmg_profile(self, _):
        self.__clear_results()

    _handler_map = {
        EffectsStarted: _handle_effects_started,
        EffectsStopped: _handle_effects_stopped,
        AttrsValueChanged: _handle_attr_changed,
        AttrsValueChangedMasked: _handle_attr_changed_masked,
        RahIncomingDmgChanged: _handle_changed_dmg_profile}

    def _notify(self, msg):
        # Do not react to messages while sim is running
        if self.__running is True:
            return
        BaseSubscriber._notify(self, msg)

    # Auxiliary message handling methods
    def __get_rah_effect(self, item):
        """Get RAH effect object for passed i."""
        try:
            return item._type_effects[EffectId.adaptive_armor_hardener]
        except KeyError:
            return None

    def __get_rah_duration(self, item):
        """Get time it takes for RAH effect to complete one cycle."""
        effect = self.__get_rah_effect(item)
        if effect is None:
            return None
        return effect.get_duration(item)

    def __clear_results(self):
        """Remove simulation results, if there're any."""
        for item, resos in self.__data.items():
            resos.clear()
            for attr_id in res_attr_ids:
                item.attrs._override_value_may_change(attr_id)
