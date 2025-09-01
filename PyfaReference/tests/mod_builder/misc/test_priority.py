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


from eos.const.eos import EffectBuildStatus
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.const.eve import OperandId
from tests.mod_builder.testcase import ModBuilderTestCase


class TestBuilderPriority(ModBuilderTestCase):
    """Check which kind of builder is picked for which case."""

    def setUp(self):
        ModBuilderTestCase.setUp(self)
        e_tgt = self.ef.make(
            1, operandID=OperandId.def_dom, expressionValue='Ship')
        e_tgt_attr = self.ef.make(
            2, operandID=OperandId.def_attr, expressionAttributeID=9)
        e_optr = self.ef.make(
            3, operandID=OperandId.def_optr, expressionValue='PostPercent')
        e_src_attr = self.ef.make(
            4, operandID=OperandId.def_attr, expressionAttributeID=327)
        e_tgt_spec = self.ef.make(
            5, operandID=OperandId.itm_attr, arg1=e_tgt['expressionID'],
            arg2=e_tgt_attr['expressionID'])
        e_optr_tgt = self.ef.make(
            6, operandID=OperandId.optr_tgt, arg1=e_optr['expressionID'],
            arg2=e_tgt_spec['expressionID'])
        self.e_add_mod = self.ef.make(
            7, operandID=OperandId.add_itm_mod, arg1=e_optr_tgt['expressionID'],
            arg2=e_src_attr['expressionID'])
        self.e_rm_mod = self.ef.make(
            8, operandID=OperandId.rm_itm_mod, arg1=e_optr_tgt['expressionID'],
            arg2=e_src_attr['expressionID'])

    def test_etree(self):
        effect_row = {
            'preExpression': self.e_add_mod['expressionID'],
            'postExpression': self.e_rm_mod['expressionID'],
            'modifierInfo': None}
        modifiers, status = self.run_builder(effect_row)
        self.assertEqual(status, EffectBuildStatus.success)
        self.assertEqual(len(modifiers), 1)
        modifier = modifiers[0]
        self.assertEqual(modifier.affectee_filter, ModAffecteeFilter.item)
        self.assertEqual(modifier.affectee_domain, ModDomain.ship)
        self.assertIsNone(modifier.affectee_filter_extra_arg)
        self.assertEqual(modifier.affectee_attr_id, 9)
        self.assertEqual(modifier.operator, ModOperator.post_percent)
        self.assertEqual(modifier.affector_attr_id, 327)
        self.assert_log_entries(0)

    def test_modinfo(self):
        effect_row = {
            'preExpression': self.e_add_mod['expressionID'],
            'postExpression': self.e_rm_mod['expressionID'],
            'modifierInfo':
                '- domain: charID\n  func: ItemModifier\n'
                '  modifiedAttributeID: 164\n  modifyingAttributeID: 175\n'
                '  operator: 2\n'}
        modifiers, status = self.run_builder(effect_row)
        self.assertEqual(status, EffectBuildStatus.success)
        self.assertEqual(len(modifiers), 1)
        modifier = modifiers[0]
        self.assertEqual(modifier.affectee_filter, ModAffecteeFilter.item)
        self.assertEqual(modifier.affectee_domain, ModDomain.character)
        self.assertIsNone(modifier.affectee_filter_extra_arg)
        self.assertEqual(modifier.affectee_attr_id, 164)
        self.assertEqual(modifier.operator, ModOperator.mod_add)
        self.assertEqual(modifier.affector_attr_id, 175)
        self.assert_log_entries(0)
