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
from unittest.mock import patch

from eos.const.eve import EffectId
from eos.const.eve import FighterAbilityId
from tests.eve_obj_builder.testcase import EveObjBuilderTestCase


class TestPrimaryKey(EveObjBuilderTestCase):
    """Check that only valid primary keys pass checks."""

    def get_log(self, name='eos.eve_obj_builder.validator_preclean'):
        return EveObjBuilderTestCase.get_log(self, name=name)

    def test_single_proper_pk(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['evetypes'].append({'typeID': 2, 'groupID': 1})
        self.run_builder()
        self.assertIn(1, self.types)
        self.assertIn(2, self.types)
        self.assert_log_entries(0)

    def test_single_no_pk(self):
        self.dh.data['evetypes'].append({'groupID': 1})
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table evetypes have invalid PKs, removing them')

    def test_single_invalid(self):
        self.dh.data['evetypes'].append({'typeID': 1.5, 'groupID': 1})
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table evetypes have invalid PKs, removing them')

    def test_single_duplicate(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 920})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertEqual(self.types[1].group_id, 1)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table evetypes have invalid PKs, removing them')

    def test_single_duplicate_reverse(self):
        # Make sure first fed by data_handler row is accepted
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 920})
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertEqual(self.types[1].group_id, 920)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table evetypes have invalid PKs, removing them')

    def test_single_cleaned(self):
        # Make sure check is ran before cleanup
        self.dh.data['evetypes'].append({'typeID': 1})
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 920})
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table evetypes have invalid PKs, removing them')

    def test_dual_proper_pk(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 50.0})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 50, 'value': 100.0})
        self.run_builder()
        type_attrs = self.types[1].attrs
        self.assertEqual(type_attrs[100], 50.0)
        self.assertEqual(type_attrs[50], 100.0)
        self.assert_log_entries(0)

    def test_dual_no_pk(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeattribs'].append({'typeID': 1, 'value': 50.0})
        self.run_builder()
        self.assertEqual(len(self.types[1].attrs), 0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmtypeattribs have invalid PKs, removing them')

    def test_dual_invalid(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100.1, 'value': 50.0})
        self.run_builder()
        self.assertEqual(len(self.types[1].attrs), 0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmtypeattribs have invalid PKs, removing them')

    def test_dual_duplicate(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 50.0})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 5.0})
        self.run_builder()
        type_attrs = self.types[1].attrs
        self.assertEqual(len(type_attrs), 1)
        self.assertEqual(type_attrs[100], 50.0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmtypeattribs have invalid PKs, removing them')

    def test_dual_cleaned(self):
        # Make sure check is ran before cleanup
        self.dh.data['evetypes'].append({'typeID': 1})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 50.0})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 5.0})
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmtypeattribs have invalid PKs, removing them')

    def test_dual_duplicate_reverse(self):
        # Make sure first fed by data_handler row is accepted
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 5.0})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 100, 'value': 50.0})
        self.run_builder()
        type_attrs = self.types[1].attrs
        self.assertEqual(len(type_attrs), 1)
        self.assertEqual(type_attrs[100], 5.0)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmtypeattribs have invalid PKs, removing them')

    # Now, when PK-related checks cover evetypes (single PK) and dgmtypeattribs
    # (dual PK) tables, run simple tests on the rest of the tables to make sure
    # they are covered
    def test_evegroups(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['evegroups'].append({'groupID': 1, 'categoryID': 7})
        self.dh.data['evegroups'].append({'groupID': 1, 'categoryID': 32})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertEqual(self.types[1].category_id, 7)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table evegroups have invalid PKs, removing them')

    def test_dgmattribs(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeattribs'].append(
            {'typeID': 1, 'attributeID': 7, 'value': 8.0})
        self.dh.data['dgmattribs'].append(
            {'attributeID': 7, 'maxAttributeID': 50})
        self.dh.data['dgmattribs'].append(
            {'attributeID': 7, 'maxAttributeID': 55})
        self.run_builder()
        self.assertEqual(len(self.attrs), 1)
        self.assertEqual(self.attrs[7].max_attr_id, 50)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmattribs have invalid PKs, removing them')

    def test_dgmeffects(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeeffects'].append(
            {'typeID': 1, 'effectID': 7, 'isDefault': False})
        self.dh.data['dgmeffects'].append({'effectID': 7, 'effectCategory': 50})
        self.dh.data['dgmeffects'].append({'effectID': 7, 'effectCategory': 55})
        self.run_builder()
        self.assertEqual(len(self.effects), 1)
        self.assertEqual(self.effects[7].category_id, 50)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmeffects have invalid PKs, removing them')

    def test_dgmtypeeffects(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeeffects'].append(
            {'typeID': 1, 'effectID': 100, 'isDefault': True})
        self.dh.data['dgmtypeeffects'].append(
            {'typeID': 1, 'effectID': 100, 'isDefault': False})
        self.dh.data['dgmeffects'].append({'effectID': 100})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertEqual(self.types[1].default_effect.id, 100)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmtypeeffects have invalid PKs, removing them')

    @patch('eos.eve_obj_builder.converter.ModBuilder')
    def test_dgmexpressions(self, mod_builder):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeeffects'].append(
            {'typeID': 1, 'effectID': 7, 'isDefault': False})
        self.dh.data['dgmeffects'].append(
            {'effectID': 7, 'preExpression': 62, 'postExpression': 83})
        self.dh.data['dgmexpressions'].append({
            'expressionID': 83, 'operandID': 75, 'arg1': 1009, 'arg2': 15,
            'expressionValue': None, 'expressionTypeID': 502,
            'expressionGroupID': 451, 'expressionAttributeID': 90})
        self.dh.data['dgmexpressions'].append({
            'expressionID': 83, 'operandID': 80, 'arg1': 1009, 'arg2': 15,
            'expressionValue': None, 'expressionTypeID': 502,
            'expressionGroupID': 451, 'expressionAttributeID': 90})
        mod_builder.return_value.build.return_value = ([], 0)
        self.run_builder()
        expressions = tuple(mod_builder.mock_calls[0][1][0])
        self.assertEqual(len(expressions), 1)
        actual = expressions[0]
        expected = {
            'expressionID': 83, 'operandID': 75, 'arg1': 1009, 'arg2': 15,
            'expressionValue': None, 'expressionTypeID': 502,
            'expressionGroupID': 451, 'expressionAttributeID': 90}
        # Filter out fields we do not want to check
        fields_to_check = set(expected).intersection(actual)
        actual_clean = {k: actual[k] for k in fields_to_check}
        self.assertEqual(actual_clean, expected)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table dgmexpressions have invalid PKs, removing them')

    def test_fighterabilities(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.dh.data['dgmtypeeffects'].append(
            {'typeID': 1, 'effectID': EffectId.fighter_ability_attack_m})
        self.dh.data['dgmtypeeffects'].append(
            {'typeID': 1, 'effectID': EffectId.fighter_ability_microwarpdrive})
        self.dh.data['dgmeffects'].append(
            {'effectID': EffectId.fighter_ability_attack_m})
        self.dh.data['dgmeffects'].append(
            {'effectID': EffectId.fighter_ability_microwarpdrive})
        self.dh.data['typefighterabils'].append(
            {'typeID': 1, 'abilityID': FighterAbilityId.autocannon})
        self.dh.data['typefighterabils'].append(
            {'typeID': 1, 'abilityID': FighterAbilityId.microwarpdrive})
        self.dh.data['typefighterabils'].append(
            {'typeID': 1, 'abilityID': FighterAbilityId.autocannon})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        type_abilities_data = self.types[1].abilities_data
        self.assertEqual(len(type_abilities_data), 2)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            '1 rows in table typefighterabils have invalid PKs, removing them')
