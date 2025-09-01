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


from eos import ModuleMid
from eos import Ship
from eos import Subsystem
from eos.const.eve import AttrId
from tests.integration.stats.testcase import StatsTestCase


class TestSubsystem(StatsTestCase):

    def setUp(self):
        StatsTestCase.setUp(self)
        self.mkattr(attr_id=AttrId.max_subsystems)

    def test_output(self):
        self.fit.ship = Ship(self.mktype(attrs={AttrId.max_subsystems: 3}).id)
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.total, 3)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_ship_absent(self):
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_ship_attr_absent(self):
        self.fit.ship = Ship(self.mktype().id)
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_output_ship_not_loaded(self):
        self.fit.ship = Ship(self.allocate_type_id())
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.total, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_multiple(self):
        self.fit.subsystems.add(Subsystem(self.mktype().id))
        self.fit.subsystems.add(Subsystem(self.mktype().id))
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.used, 2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_class_other(self):
        self.fit.modules.mid.append(ModuleMid(self.mktype().id))
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_absent(self):
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.used, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_use_item_not_loaded(self):
        self.fit.subsystems.add(Subsystem(self.allocate_type_id()))
        # Verification
        self.assertEqual(self.fit.stats.subsystem_slots.used, 1)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
