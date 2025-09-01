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


from eos import Charge
from eos import ModuleHigh
from eos import Restriction
from eos import State
from eos.const.eve import AttrId
from eos.const.eve import EffectCategoryId
from eos.const.eve import EffectId
from tests.integration.restriction.testcase import RestrictionTestCase


class TestChargeVolume(RestrictionTestCase):
    """Check functionality of charge volume restriction."""

    def test_fail_charge_attr_greater(self):
        charge = Charge(self.mktype(attrs={AttrId.volume: 2}).id)
        container = ModuleHigh(
            self.mktype(attrs={AttrId.capacity: 1}).id,
            state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNotNone(error2)
        self.assertEqual(error2.volume, 2)
        self.assertEqual(error2.max_allowed_volume, 1)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fail_container_attr_absent(self):
        charge = Charge(self.mktype(attrs={AttrId.volume: 2}).id)
        container = ModuleHigh(self.mktype().id, state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNotNone(error2)
        self.assertEqual(error2.volume, 2)
        self.assertEqual(error2.max_allowed_volume, 0)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_charge_attr_equal(self):
        charge = Charge(self.mktype(attrs={AttrId.volume: 2}).id)
        container = ModuleHigh(
            self.mktype(attrs={AttrId.capacity: 2}).id,
            state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_charge_attr_lesser(self):
        charge = Charge(self.mktype(attrs={AttrId.volume: 2}).id)
        container = ModuleHigh(
            self.mktype(attrs={AttrId.capacity: 3}).id,
            state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_charge_attr_absent(self):
        charge = Charge(self.mktype().id)
        container = ModuleHigh(
            self.mktype(attrs={AttrId.volume: 3}).id,
            state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_charge_not_loaded(self):
        charge = Charge(self.allocate_type_id())
        container = ModuleHigh(
            self.mktype(attrs={AttrId.volume: 3}).id,
            state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_autocharge(self):
        # Make sure autocharge volume is ignored
        autocharge_type = self.mktype(attrs={AttrId.volume: 2})
        container_effect = self.mkeffect(
            effect_id=EffectId.target_attack,
            category_id=EffectCategoryId.target)
        container = ModuleHigh(
            self.mktype(
                attrs={
                    AttrId.capacity: 1,
                    AttrId.ammo_loaded: autocharge_type.id},
                effects=[container_effect]).id,
            state=State.offline)
        self.fit.modules.high.append(container)
        self.assertIn(container_effect.id, container.autocharges)
        autocharge = container.autocharges[container_effect.id]
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(autocharge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_autocharge_not_loaded(self):
        container_effect = self.mkeffect(
            effect_id=EffectId.target_attack,
            category_id=EffectCategoryId.target)
        container = ModuleHigh(
            self.mktype(
                attrs={
                    AttrId.capacity: 1,
                    AttrId.ammo_loaded: self.allocate_type_id()},
                effects=[container_effect]).id,
            state=State.offline)
        self.fit.modules.high.append(container)
        self.assertIn(container_effect.id, container.autocharges)
        autocharge = container.autocharges[container_effect.id]
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(autocharge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_autocharge_with_charge(self):
        charge = Charge(self.mktype(attrs={AttrId.volume: 2}).id)
        autocharge_type = self.mktype(attrs={AttrId.volume: 2})
        container_effect = self.mkeffect(
            effect_id=EffectId.target_attack,
            category_id=EffectCategoryId.target)
        container = ModuleHigh(
            self.mktype(
                attrs={
                    AttrId.capacity: 2,
                    AttrId.ammo_loaded: autocharge_type.id},
                effects=[container_effect]).id,
            state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        self.assertIn(container_effect.id, container.autocharges)
        autocharge = container.autocharges[container_effect.id]
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Action
        error3 = self.get_error(autocharge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error3)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_pass_container_not_loaded(self):
        charge = Charge(self.mktype(attrs={AttrId.volume: 2}).id)
        container = ModuleHigh(self.allocate_type_id(), state=State.offline)
        container.charge = charge
        self.fit.modules.high.append(container)
        # Action
        error1 = self.get_error(container, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error1)
        # Action
        error2 = self.get_error(charge, Restriction.charge_volume)
        # Verification
        self.assertIsNone(error2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
