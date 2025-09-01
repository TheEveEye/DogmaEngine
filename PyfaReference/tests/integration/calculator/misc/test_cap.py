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


from eos import Implant
from eos import Rig
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import EffectCategoryId
from tests.integration.calculator.testcase import CalculatorTestCase


class TestCap(CalculatorTestCase):
    """Test how capped attribute values are processed."""

    def setUp(self):
        CalculatorTestCase.setUp(self)
        self.capping_attr = self.mkattr(default_value=5)
        self.capped_attr = self.mkattr(max_attr_id=self.capping_attr.id)
        self.src_attr = self.mkattr()
        # Just to make sure cap is applied to final value, not base, make some
        # basic modification modifier
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.capped_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=self.src_attr.id)
        self.effect = self.mkeffect(
            category_id=EffectCategoryId.passive, modifiers=[modifier])

    def test_cap_default(self):
        # Check that cap is applied properly when item doesn't have base value
        # of capping attribute
        item = Implant(self.mktype(
            attrs={self.capped_attr.id: 3, self.src_attr.id: 6},
            effects=[self.effect]).id)
        self.fit.implants.add(item)
        # Verification
        self.assertAlmostEqual(item.attrs[self.capped_attr.id], 5)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_cap_attr_unmodified(self):
        # Make sure that item's own specified attribute value is taken as cap
        item = Implant(self.mktype(
            attrs={
                self.capped_attr.id: 3, self.src_attr.id: 6,
                self.capping_attr.id: 2},
            effects=[self.effect]).id)
        self.fit.implants.add(item)
        # Verification
        self.assertAlmostEqual(item.attrs[self.capped_attr.id], 2)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_cap_attr_modified(self):
        # Make sure that item's own specified attribute value is taken as cap,
        # and it's taken with all modifications applied onto it
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.capping_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=self.src_attr.id)
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive, modifiers=[modifier])
        item = Implant(self.mktype(
            attrs={
                self.capped_attr.id: 3, self.src_attr.id: 6,
                self.capping_attr.id: 0.1},
            effects=(self.effect, effect)).id)
        self.fit.implants.add(item)
        # Verification
        # Attr value is 3 * 6 = 18, but cap value is 0.1 * 6 = 0.6
        self.assertAlmostEqual(item.attrs[self.capped_attr.id], 0.6)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)

    def test_cap_update(self):
        # If cap updates, capped attributes should be updated too
        item = Rig(self.mktype(
            attrs={
                self.capped_attr.id: 3, self.src_attr.id: 6,
                self.capping_attr.id: 2},
            effects=[self.effect]).id)
        self.fit.rigs.add(item)
        # Check attribute vs initial cap
        self.assertAlmostEqual(item.attrs[self.capped_attr.id], 2)
        # Add something which changes capping attribute
        modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.domain,
            affectee_domain=ModDomain.ship,
            affectee_attr_id=self.capping_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=self.src_attr.id)
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive, modifiers=[modifier])
        cap_updater = Implant(self.mktype(
            attrs={self.src_attr.id: 3.5}, effects=[effect]).id)
        self.fit.implants.add(cap_updater)
        # Verification
        # As capping attribute is updated, capped attribute must be updated too
        self.assertAlmostEqual(item.attrs[self.capped_attr.id], 7)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(0)
