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


from eos import Character
from eos import Drone
from eos import ModuleMid
from eos import State
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import AttrId
from eos.const.eve import EffectCategoryId
from tests.integration.stats.testcase import StatsTestCase


class TestLaunchedDrone(StatsTestCase):

    def setUp(self):
        StatsTestCase.setUp(self)
        self.mkattr(attr_id=AttrId.max_active_drones)

    def test_output(self):
        src_attr = self.mkattr()
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=AttrId.max_active_drones,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr.id)
        mod_effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=[modifier])
        self.fit.character = Character(self.mktype(
            attrs={AttrId.max_active_drones: 3, src_attr.id: 2},
            effects=[mod_effect]).id)
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.total, 6)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_char_absent(self):
        self.fit.character = None
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_char_attr_absent(self):
        self.fit.character = Character(self.mktype().id)
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_char_not_loaded(self):
        self.fit.character = Character(self.allocate_type_id())
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_multiple(self):
        self.fit.drones.add(Drone(self.mktype().id, state=State.online))
        self.fit.drones.add(Drone(self.mktype().id, state=State.online))
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.used, 2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_state(self):
        self.fit.drones.add(Drone(self.mktype().id, state=State.offline))
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_class_other(self):
        self.fit.modules.mid.append(
            ModuleMid(self.mktype().id, state=State.online))
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_absent(self):
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_not_loaded(self):
        self.fit.drones.add(Drone(self.allocate_type_id(), state=State.online))
        # Verification
        self.assertEqual(self.fit.stats.launched_drones.used, 1)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
