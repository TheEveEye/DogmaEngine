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


import logging

from eos import Rig
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import EffectCategoryId
from tests.integration.calculator.testcase import CalculatorTestCase


class TestAffecteeFilterUnknown(CalculatorTestCase):

    def setUp(self):
        CalculatorTestCase.setUp(self)
        self.tgt_attr = tgt_attr = self.mkattr()
        self.src_attr = src_attr = self.mkattr()
        self.invalid_modifier = self.mkmod(
            affectee_filter=26500,
            affectee_domain=ModDomain.self,
            affectee_attr_id=tgt_attr.id,
            operator=ModOperator.post_percent,
            affector_attr_id=src_attr.id)

    def test_log(self):
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=(self.invalid_modifier,))
        item_type = self.mktype(
            attrs={self.src_attr.id: 20, self.tgt_attr: 100},
            effects=[effect])
        item = Rig(item_type.id)
        # Action
        self.fit.rigs.add(item)
        # Verification
        self.assert_log_entries(2)
        for log_record in self.log:
            self.assertEqual(log_record.name, 'eos.calculator.affection')
            self.assertEqual(log_record.levelno, logging.WARNING)
            self.assertEqual(
                log_record.msg,
                'malformed modifier on item type {}: '
                'invalid affectee filter 26500'.format(item_type.id))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)

    def test_combination(self):
        valid_modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=self.tgt_attr.id,
            operator=ModOperator.post_percent,
            affector_attr_id=self.src_attr.id)
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=(self.invalid_modifier, valid_modifier))
        item = Rig(self.mktype(
            attrs={self.src_attr.id: 20, self.tgt_attr.id: 100},
            effects=[effect]).id)
        # Action
        self.fit.rigs.add(item)
        # Verification
        # Invalid filter type in modifier should prevent proper processing of
        # other modifiers
        self.assertAlmostEqual(item.attrs[self.tgt_attr.id], 120)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
