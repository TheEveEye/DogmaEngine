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
from eos import ModuleHigh
from eos import Restriction
from eos.const.eve import AttrId
from tests.integration.restriction.testcase import RestrictionTestCase


class TestMaxGroupFitted(RestrictionTestCase):
    """Check functionality of max group fitted restriction."""

    def setUp(self):
        RestrictionTestCase.setUp(self)
        self.mkattr(attr_id=AttrId.max_group_fitted)

    def test_fail_all(self):
        # Make sure error is raised for all items exceeding their group
        # restriction
        item_type = self.mktype(
            group_id=6,
            attrs={AttrId.max_group_fitted: 1})
        item1 = ModuleHigh(item_type.id)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(item_type.id)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.max_group_fitted)
        # Verification
        self.assertIsNotNone(error1)
        self.assertEqual(error1.group_id, 6)
        self.assertEqual(error1.quantity, 2)
        self.assertEqual(error1.max_allowed_quantity, 1)
        # Action
        error2 = self.get_error(item2, Restriction.max_group_fitted)
        # Verification
        self.assertIsNotNone(error2)
        self.assertEqual(error2.group_id, 6)
        self.assertEqual(error2.quantity, 2)
        self.assertEqual(error2.max_allowed_quantity, 1)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_mix_one(self):
        # Make sure error is raised for just items which excess restriction,
        # even if both are from the same group
        item1 = ModuleHigh(self.mktype(
            group_id=92,
            attrs={AttrId.max_group_fitted: 1}).id)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(self.mktype(
            group_id=92,
            attrs={AttrId.max_group_fitted: 2}).id)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.max_group_fitted)
        # Verification
        self.assertIsNotNone(error1)
        self.assertEqual(error1.group_id, 92)
        self.assertEqual(error1.quantity, 2)
        self.assertEqual(error1.max_allowed_quantity, 1)
        # Action
        error2 = self.get_error(item2, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass(self):
        # Make sure no errors are raised when quantity of added items doesn't
        # exceed any restrictions
        item_type = self.mktype(
            group_id=860,
            attrs={AttrId.max_group_fitted: 2})
        item1 = ModuleHigh(item_type.id)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(item_type.id)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(item2, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_group_none(self):
        # Check that items with None group are not affected
        item_type = self.mktype(
            group_id=None,
            attrs={AttrId.max_group_fitted: 1})
        item1 = ModuleHigh(item_type.id)
        self.fit.modules.high.append(item1)
        item2 = ModuleHigh(item_type.id)
        self.fit.modules.high.append(item2)
        # Action
        error1 = self.get_error(item1, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(item2, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_class_other(self):
        item_type = self.mktype(
            group_id=12,
            attrs={AttrId.max_group_fitted: 1})
        item1 = Drone(item_type.id)
        self.fit.drones.add(item1)
        item2 = Drone(item_type.id)
        self.fit.drones.add(item2)
        # Action
        error1 = self.get_error(item1, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(item2, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_not_loaded(self):
        item = ModuleHigh(self.allocate_type_id())
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.max_group_fitted)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
