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


from eos import EffectMode
from eos import ModuleHigh
from eos import Restriction
from eos import Ship
from eos import State
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import AttrId
from eos.const.eve import EffectCategoryId
from eos.const.eve import EffectId
from tests.integration.restriction.testcase import RestrictionTestCase


class TestPowerGrid(RestrictionTestCase):
    """Check functionality of power grid restriction."""

    def setUp(self):
        RestrictionTestCase.setUp(self)
        self.mkattr(attr_id=AttrId.power)
        self.mkattr(attr_id=AttrId.power_output)
        self.effect = self.mkeffect(
            effect_id=EffectId.online,
            category_id=EffectCategoryId.online)

    def test_fail_single(self):
        # When ship provides powergrid output, but single consumer demands for
        # more, error should be raised
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 40}).id)
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 50}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error)
        self.assertEqual(error.output, 40)
        self.assertEqual(error.total_use, 50)
        self.assertEqual(error.item_use, 50)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_multiple(self):
        # When multiple consumers require less than powergrid output alone, but
        # in sum want more than total output, it should be erroneous situation
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 40}).id)
        item1 = ModuleHigh(
            self.mktype(attrs={AttrId.power: 25}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(
            self.mktype(attrs={AttrId.power: 20}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error1)
        self.assertEqual(error1.output, 40)
        self.assertEqual(error1.total_use, 45)
        self.assertEqual(error1.item_use, 25)
        # Action
        error2 = self.get_error(item2, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error2)
        self.assertEqual(error2.output, 40)
        self.assertEqual(error2.total_use, 45)
        self.assertEqual(error2.item_use, 20)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_modified(self):
        # Make sure modified powergrid values are taken
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 50}).id)
        src_attr = self.mkattr()
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=AttrId.power,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr.id)
        mod_effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=[modifier])
        item = ModuleHigh(
            self.mktype(
                attrs={AttrId.power: 50, src_attr.id: 2},
                effects=(self.effect, mod_effect)).id,
            state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error)
        self.assertEqual(error.output, 50)
        self.assertEqual(error.total_use, 100)
        self.assertEqual(error.item_use, 100)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_ship_absent(self):
        # When stats module does not specify output, make sure it's assumed to
        # be 0
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 5}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error)
        self.assertEqual(error.output, 0)
        self.assertEqual(error.total_use, 5)
        self.assertEqual(error.item_use, 5)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_ship_attr_absent(self):
        self.fit.ship = Ship(self.mktype().id)
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 50}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error)
        self.assertEqual(error.output, 0)
        self.assertEqual(error.total_use, 50)
        self.assertEqual(error.item_use, 50)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_ship_not_loaded(self):
        self.fit.ship = Ship(self.allocate_type_id())
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 5}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error)
        self.assertEqual(error.output, 0)
        self.assertEqual(error.total_use, 5)
        self.assertEqual(error.item_use, 5)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_mix_usage_zero(self):
        # If some item has zero usage and powergrid error is still raised, check
        # it's not raised for item with zero usage
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 50}).id)
        item1 = ModuleHigh(
            self.mktype(attrs={AttrId.power: 100}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(
            self.mktype(attrs={AttrId.power: 0}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.powergrid)
        # Verification
        self.assertIsNotNone(error1)
        self.assertEqual(error1.output, 50)
        self.assertEqual(error1.total_use, 100)
        self.assertEqual(error1.item_use, 100)
        # Action
        error2 = self.get_error(item2, Restriction.powergrid)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass(self):
        # When total consumption is less than output, no errors should be raised
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 50}).id)
        item1 = ModuleHigh(
            self.mktype(attrs={AttrId.power: 25}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(
            self.mktype(attrs={AttrId.power: 20}, effects=[self.effect]).id,
            state=State.online)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.powergrid)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(item2, Restriction.powergrid)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_state(self):
        # When item isn't online, it shouldn't consume anything
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 40}).id)
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 50}, effects=[self.effect]).id,
            state=State.offline)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_effect_disabled(self):
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 40}).id)
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 50}, effects=[self.effect]).id,
            state=State.online)
        item.set_effect_mode(self.effect.id, EffectMode.force_stop)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_effect_absent(self):
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 40}).id)
        item = ModuleHigh(
            self.mktype(attrs={AttrId.power: 50}).id,
            state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_not_loaded(self):
        self.fit.ship = Ship(self.mktype(attrs={AttrId.power_output: 0}).id)
        item = ModuleHigh(self.allocate_type_id(), state=State.online)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.powergrid)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
