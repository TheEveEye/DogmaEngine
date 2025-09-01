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
from eos import Fit
from eos import ModuleHigh
from eos import State
from eos.const.eve import AttrId
from eos.const.eve import EffectCategoryId
from eos.const.eve import EffectId
from tests.integration.item.testcase import ItemMixinTestCase


class TestItemDmgTurretLaserDps(ItemMixinTestCase):

    def setUp(self):
        ItemMixinTestCase.setUp(self)
        self.mkattr(attr_id=AttrId.capacity)
        self.mkattr(attr_id=AttrId.volume)
        self.mkattr(attr_id=AttrId.crystals_get_damaged)
        self.mkattr(attr_id=AttrId.hp)
        self.mkattr(attr_id=AttrId.crystal_volatility_chance)
        self.mkattr(attr_id=AttrId.crystal_volatility_dmg)
        self.mkattr(attr_id=AttrId.reload_time)
        self.mkattr(attr_id=AttrId.dmg_mult)
        self.mkattr(attr_id=AttrId.em_dmg)
        self.mkattr(attr_id=AttrId.therm_dmg)
        self.mkattr(attr_id=AttrId.kin_dmg)
        self.mkattr(attr_id=AttrId.expl_dmg)
        self.cycle_attr = self.mkattr()
        self.effect = self.mkeffect(
            effect_id=EffectId.target_attack,
            category_id=EffectCategoryId.target,
            duration_attr_id=self.cycle_attr.id)

    def test_no_reload(self):
        fit = Fit()
        item = ModuleHigh(
            self.mktype(
                attrs={
                    AttrId.dmg_mult: 2.5,
                    AttrId.capacity: 2.0,
                    self.cycle_attr.id: 500,
                    AttrId.reload_time: 5000},
                effects=[self.effect],
                default_effect=self.effect).id,
            state=State.active)
        item.charge = Charge(self.mktype(attrs={
            AttrId.volume: 0.2,
            AttrId.hp: 2.0,
            AttrId.crystals_get_damaged: 1.0,
            AttrId.crystal_volatility_dmg: 0.025,
            AttrId.crystal_volatility_chance: 0.1,
            AttrId.em_dmg: 5.2,
            AttrId.therm_dmg: 6.3,
            AttrId.kin_dmg: 7.4,
            AttrId.expl_dmg: 8.5}).id)
        fit.modules.high.append(item)
        # Verification
        dps = item.get_dps(reload=False)
        self.assertAlmostEqual(dps.em, 26)
        self.assertAlmostEqual(dps.thermal, 31.5)
        self.assertAlmostEqual(dps.kinetic, 37)
        self.assertAlmostEqual(dps.explosive, 42.5)
        self.assertAlmostEqual(dps.total, 137)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_reload(self):
        fit = Fit()
        item = ModuleHigh(
            self.mktype(
                attrs={
                    AttrId.dmg_mult: 2.5,
                    AttrId.capacity: 0.2,
                    self.cycle_attr.id: 500,
                    AttrId.reload_time: 5000},
                effects=[self.effect],
                default_effect=self.effect).id,
            state=State.active)
        item.charge = Charge(self.mktype(attrs={
            AttrId.volume: 0.1,
            AttrId.hp: 2.0,
            AttrId.crystals_get_damaged: 1.0,
            AttrId.crystal_volatility_dmg: 0.8,
            AttrId.crystal_volatility_chance: 0.5,
            AttrId.em_dmg: 5.2,
            AttrId.therm_dmg: 6.3,
            AttrId.kin_dmg: 7.4,
            AttrId.expl_dmg: 8.5}).id)
        fit.modules.high.append(item)
        # Verification
        dps = item.get_dps(reload=True)
        self.assertAlmostEqual(dps.em, 13)
        self.assertAlmostEqual(dps.thermal, 15.75)
        self.assertAlmostEqual(dps.kinetic, 18.5)
        self.assertAlmostEqual(dps.explosive, 21.25)
        self.assertAlmostEqual(dps.total, 68.5)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)
