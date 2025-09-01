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


class TestOperatorUnknown(CalculatorTestCase):

    def test_log_other(self):
        # Check how unknown operator value influences attribute calculator
        tgt_attr = self.mkattr()
        src_attr = self.mkattr()
        invalid_modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=tgt_attr.id,
            operator=1008,
            affector_attr_id=src_attr.id)
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive, modifiers=[invalid_modifier])
        item_type = self.mktype(
            attrs={src_attr.id: 1.2, tgt_attr.id: 100}, effects=[effect])
        item = Rig(item_type.id)
        # Action
        self.fit.rigs.add(item)
        # Verification
        self.assertAlmostEqual(item.attrs[tgt_attr.id], 100)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.name, 'eos.calculator.map')
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            'malformed modifier on item type {}: '
            'unknown operator 1008'.format(item_type.id))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)

    def test_log_unorderable_combination(self):
        # Check how non-orderable operator value influences attribute
        # calculator. Previously, bug in calculation method made it to crash
        tgt_attr = self.mkattr()
        src_attr = self.mkattr()
        invalid_modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=tgt_attr.id,
            operator=None,
            affector_attr_id=src_attr.id)
        valid_modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr.id)
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=(invalid_modifier, valid_modifier))
        item_type = self.mktype(
            attrs={src_attr.id: 1.2, tgt_attr.id: 100},
            effects=[effect])
        item = Rig(item_type.id)
        # Action
        self.fit.rigs.add(item)
        # Verification
        self.assertAlmostEqual(item.attrs[tgt_attr.id], 120)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.name, 'eos.calculator.map')
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            'malformed modifier on item type {}: '
            'unknown operator None'.format(item_type.id))
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)

    def test_combination(self):
        tgt_attr = self.mkattr()
        src_attr = self.mkattr()
        invalid_modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=tgt_attr.id,
            operator=1008,
            affector_attr_id=src_attr.id)
        valid_modifier = self.mkmod(
            affectee_filter=ModAffecteeFilter.item,
            affectee_domain=ModDomain.self,
            affectee_attr_id=tgt_attr.id,
            operator=ModOperator.post_mul,
            affector_attr_id=src_attr.id)
        effect = self.mkeffect(
            category_id=EffectCategoryId.passive,
            modifiers=(invalid_modifier, valid_modifier))
        item = Rig(self.mktype(
            attrs={src_attr.id: 1.5, tgt_attr.id: 100},
            effects=[effect]).id)
        # Action
        self.fit.rigs.add(item)
        # Verification
        # Make sure presence of invalid operator doesn't prevent from
        # calculating value based on valid modifiers
        self.assertAlmostEqual(item.attrs[tgt_attr.id], 150)
        # Cleanup
        self.assert_solsys_buffers_empty(self.fit.solar_system)
        self.assert_log_entries(1)
