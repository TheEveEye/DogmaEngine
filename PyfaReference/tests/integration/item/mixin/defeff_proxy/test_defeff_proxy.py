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


from eos import Fit
from eos import ModuleHigh
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import EffectCategoryId
from tests.integration.item.testcase import ItemMixinTestCase


class TestItemMixinDefEffProxy(ItemMixinTestCase):

    def make_item_with_defeff_attr(self, defeff_attr_name):
        attr = self.mkattr()
        src_attr = self.mkattr()
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr.id)
        mod_effect1 = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=[modifier])
        mod_effect2 = self.mkeffect(
            category_id=EffectCategoryId.online,
            modifiers=[modifier])
        def_effect = self.mkeffect(
            category_id=EffectCategoryId.active,
            **{defeff_attr_name: attr.id})
        item = ModuleHigh(self.mktype(
            attrs={attr.id: 50, src_attr.id: 2},
            effects=(mod_effect1, mod_effect2, def_effect),
            default_effect=def_effect).id)
        return item

    def test_cycle(self):
        fit = Fit()
        item = self.make_item_with_defeff_attr('duration_attr_id')
        fit.modules.high.append(item)
        # Verification
        # Cycle time is divided by 1000, as it's defined in ms
        self.assertAlmostEqual(item.cycle_time, 0.1)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_optimal(self):
        fit = Fit()
        item = self.make_item_with_defeff_attr('range_attr_id')
        fit.modules.high.append(item)
        # Verification
        self.assertAlmostEqual(item.optimal_range, 100)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_falloff(self):
        fit = Fit()
        item = self.make_item_with_defeff_attr('falloff_attr_id')
        fit.modules.high.append(item)
        # Verification
        self.assertAlmostEqual(item.falloff_range, 100)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_tracking(self):
        fit = Fit()
        item = self.make_item_with_defeff_attr('tracking_speed_attr_id')
        fit.modules.high.append(item)
        # Verification
        self.assertAlmostEqual(item.tracking_speed, 100)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    # Various errors are tested here, but just for one of access points
    def test_item_defeff_absent(self):
        attr = self.mkattr()
        effect = self.mkeffect(
            category_id=EffectCategoryId.active,
            range_attr_id=attr.id)
        fit = Fit()
        item = ModuleHigh(self.mktype(attrs={attr.id: 50}, effects=[effect]).id)
        fit.modules.high.append(item)
        # Verification
        self.assertIsNone(item.optimal_range)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_item_attr_desc_absent(self):
        attr = self.mkattr()
        effect = self.mkeffect(category_id=EffectCategoryId.active)
        fit = Fit()
        item = ModuleHigh(self.mktype(
            attrs={attr.id: 50},
            effects=[effect],
            default_effect=effect).id)
        fit.modules.high.append(item)
        # Verification
        self.assertIsNone(item.optimal_range)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_item_attr_value_absent(self):
        attr = self.mkattr()
        effect = self.mkeffect(
            category_id=EffectCategoryId.active,
            range_attr_id=attr.id)
        fit = Fit()
        item = ModuleHigh(self.mktype(
            effects=[effect],
            default_effect=effect).id)
        fit.modules.high.append(item)
        # Verification
        self.assertIsNone(item.optimal_range)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_cycle_item_not_loaded(self):
        fit = Fit()
        item = ModuleHigh(self.allocate_type_id())
        fit.modules.high.append(item)
        # Verification
        self.assertIsNone(item.cycle_time)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)

    def test_optimal_item_not_loaded(self):
        fit = Fit()
        item = ModuleHigh(self.allocate_type_id())
        fit.modules.high.append(item)
        # Verification
        self.assertIsNone(item.optimal_range)
        # Cleanup
        self.assert_solsys_buffers_empty(fit.solar_system)
        self.assert_log_entries(0)
