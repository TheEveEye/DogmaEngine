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
from eos import State
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import EffectCategoryId
from eos.const.eve import EffectId
from tests.integration.calculator.testcase import CalculatorTestCase


class TestStateSwitching(CalculatorTestCase):

    def setUp(self):
        CalculatorTestCase.setUp(self)
        self.tgt_attr = self.mkattr(stackable=1)
        src_attr1 = self.mkattr()
        src_attr2 = self.mkattr()
        src_attr3 = self.mkattr()
        src_attr4 = self.mkattr()
        src_attr5 = self.mkattr()
        modifier_off = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr1.id)
        modifier_on = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr2.id)
        modifier_act = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr3.id)
        modifier_over = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr4.id)
        modifier_disabled = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr3.id)
        effect_cat_offline = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=[modifier_off])
        effect_cat_online = self.mkeffect(
            category_id=EffectCategoryId.online,
            modifiers=[modifier_on])
        effect_cat_active = self.mkeffect(
            category_id=EffectCategoryId.active,
            modifiers=[modifier_act])
        effect_cat_overload = self.mkeffect(
            category_id=EffectCategoryId.overload,
            modifiers=[modifier_over])
        online_effect = self.mkeffect(
            effect_id=EffectId.online,
            category_id=EffectCategoryId.online)
        effect_disabled = self.mkeffect(
            category_id=EffectCategoryId.online,
            modifiers=[modifier_disabled])
        self.item = ModuleHigh(self.mktype(
            attrs={
                self.tgt_attr.id: 100, src_attr1.id: 1.1, src_attr2.id: 1.3,
                src_attr3.id: 1.5, src_attr4.id: 1.7, src_attr5.id: 2},
            effects=(
                effect_cat_offline, effect_cat_online, effect_cat_active,
                effect_cat_overload, online_effect, effect_disabled),
            default_effect=effect_cat_active).id)
        self.item.set_effect_mode(effect_disabled.id, EffectMode.force_stop)

    def test_fit_offline(self):
        # Setup
        self.item.state = State.offline
        # Action
        self.fit.modules.high.append(self.item)
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 110)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fit_online(self):
        # Setup
        self.item.state = State.online
        # Action
        self.fit.modules.high.append(self.item)
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 143)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fit_active(self):
        # Setup
        self.item.state = State.active
        # Action
        self.fit.modules.high.append(self.item)
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 214.5)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_fit_overloaded(self):
        # Setup
        self.item.state = State.overload
        # Action
        self.fit.modules.high.append(self.item)
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 364.65)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_switch_up_single(self):
        # Setup
        self.item.state = State.offline
        self.fit.modules.high.append(self.item)
        # Action
        self.item.state = State.online
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 143)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_switch_up_multiple(self):
        # Setup
        self.item.state = State.online
        self.fit.modules.high.append(self.item)
        # Action
        self.item.state = State.overload
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 364.65)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_switch_down_single(self):
        # Setup
        self.item.state = State.overload
        self.fit.modules.high.append(self.item)
        # Action
        self.item.state = State.active
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 214.5)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_switch_down_multiple(self):
        # Setup
        self.item.state = State.active
        self.fit.modules.high.append(self.item)
        # Action
        self.item.state = State.offline
        # Verification
        self.assertAlmostEqual(self.item.attrs[self.tgt_attr.id], 110)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
