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


from eos import ModuleHigh
from eos import Restriction
from eos import Rig
from eos import Skill
from eos.const.eve import AttrId
from tests.integration.restriction.testcase import RestrictionTestCase


class TestSkillRequirement(RestrictionTestCase):
    """Check functionality of skill requirement restriction."""

    def test_fail_single(self):
        # Check that error is raised when skill requirement is not met
        item = ModuleHigh(self.mktype(attrs={
            AttrId.required_skill_1: 50,
            AttrId.required_skill_1_level: 3}).id)
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNotNone(error)
        self.assertCountEqual(error, ((50, None, 3),))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_multiple(self):
        # Check that multiple errors are shown as iterable
        item = ModuleHigh(self.mktype(attrs={
            AttrId.required_skill_1: 48,
            AttrId.required_skill_1_level: 1,
            AttrId.required_skill_2: 50,
            AttrId.required_skill_2_level: 5}).id)
        self.fit.modules.high.append(item)
        self.fit.skills.add(Skill(self.mktype(type_id=50).id, level=2))
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNotNone(error)
        self.assertCountEqual(error, ((50, 2, 5), (48, None, 1)))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_partial(self):
        # Make sure satisfied skill requirements are not shown up in error
        item = ModuleHigh(self.mktype(attrs={
            AttrId.required_skill_1: 48,
            AttrId.required_skill_1_level: 1,
            AttrId.required_skill_2: 50,
            AttrId.required_skill_2_level: 5}).id)
        self.fit.modules.high.append(item)
        self.fit.skills.add(Skill(self.mktype(type_id=48).id, level=5))
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNotNone(error)
        self.assertCountEqual(error, ((50, None, 5),))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_replacement(self):
        # Check that failed attempt to replace skill doesn't affect restriction
        item = ModuleHigh(self.mktype(attrs={
            AttrId.required_skill_1: 50,
            AttrId.required_skill_1_level: 3}).id)
        self.fit.modules.high.append(item)
        skill_type = self.mktype(type_id=50)
        self.fit.skills.add(Skill(skill_type.id, level=1))
        with self.assertRaises(ValueError):
            self.fit.skills.add(Skill(skill_type.id, level=5))
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNotNone(error)
        self.assertCountEqual(error, ((50, 1, 3),))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_skill_not_loaded(self):
        item = ModuleHigh(self.mktype(attrs={
            AttrId.required_skill_2: 50,
            AttrId.required_skill_2_level: 3}).id)
        self.fit.modules.high.append(item)
        self.fit.skills.add(Skill(self.allocate_type_id(), level=3))
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNotNone(error)
        self.assertCountEqual(error, ((50, None, 3),))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_satisfied(self):
        # Check that error isn't raised when all skill requirements are met
        item = ModuleHigh(self.mktype(attrs={
            AttrId.required_skill_2: 50,
            AttrId.required_skill_2_level: 3}).id)
        self.fit.modules.high.append(item)
        self.fit.skills.add(Skill(self.mktype(type_id=50).id, level=3))
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_exception_rig(self):
        # Check that skillreqs on rigs are not checked
        item = Rig(self.mktype(attrs={
            AttrId.required_skill_2: 50,
            AttrId.required_skill_2_level: 3}).id)
        self.fit.rigs.add(item)
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_item_not_loaded(self):
        item = ModuleHigh(self.allocate_type_id())
        self.fit.modules.high.append(item)
        # Action
        error = self.get_error(item, Restriction.skill_requirement)
        # Verification
        self.assertIsNone(error)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
