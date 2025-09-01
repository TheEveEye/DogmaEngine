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


from eos import Drone
from eos import FighterSquad
from eos import Ship
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import AttrId
from eos.const.eve import EffectCategoryId
from tests.integration.stats.testcase import StatsTestCase


class TestFighterSquadHeavy(StatsTestCase):

    def setUp(self):
        StatsTestCase.setUp(self)
        self.mkattr(attr_id=AttrId.fighter_heavy_slots)

    def test_output(self):
        src_attr = self.mkattr()
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=AttrId.fighter_heavy_slots,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr.id)
        mod_effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=[modifier])
        self.fit.ship = Ship(self.mktype(
            attrs={AttrId.fighter_heavy_slots: 3, src_attr.id: 2},
            effects=[mod_effect]).id)
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.total, 6)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_ship_absent(self):
        self.fit.ship = None
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_ship_attr_absent(self):
        self.fit.ship = Ship(self.mktype().id)
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_ship_not_loaded(self):
        self.fit.ship = Ship(self.allocate_type_id())
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_multiple(self):
        item_type = self.mktype(attrs={AttrId.fighter_squadron_is_heavy: 1.0})
        self.fit.fighters.add(FighterSquad(item_type.id))
        self.fit.fighters.add(FighterSquad(item_type.id))
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.used, 2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_attr_absent(self):
        self.fit.fighters.add(FighterSquad(self.mktype().id))
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_attr_zero(self):
        self.fit.fighters.add(FighterSquad(self.mktype(
            attrs={AttrId.fighter_squadron_is_heavy: 0.0}).id))
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_class_other(self):
        self.fit.drones.add(Drone(self.mktype(
            attrs={AttrId.fighter_squadron_is_heavy: 1.0}).id))
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_absent(self):
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_not_loaded(self):
        self.fit.fighters.add(FighterSquad(self.allocate_type_id()))
        # Verification
        self.assertEqual(self.fit.stats.fighter_squads_heavy.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
