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

from tests.eve_obj_builder.testcase import EveObjBuilderTestCase


class TestDefaultEffects(EveObjBuilderTestCase):
    """Check that each item can have has max 1 default effect."""

    def get_log(self, name='eos.eve_obj_builder.validator_preconv'):
        return EveObjBuilderTestCase.get_log(self, name=name)

    def setUp(self):
        EveObjBuilderTestCase.setUp(self)
        self.type = {'typeID': 1, 'groupID': 1}
        self.dh.data['evetypes'].append(self.type)
        self.eff_link1 = {'typeID': 1, 'effectID': 1}
        self.eff_link2 = {'typeID': 1, 'effectID': 2}
        self.dh.data['dgmtypeeffects'].append(self.eff_link1)
        self.dh.data['dgmtypeeffects'].append(self.eff_link2)
        self.dh.data['dgmeffects'].append(
            {'effectID': 1, 'falloffAttributeID': 10})
        self.dh.data['dgmeffects'].append(
            {'effectID': 2, 'falloffAttributeID': 20})

    def test_normal(self):
        self.eff_link1['isDefault'] = False
        self.eff_link2['isDefault'] = True
        self.run_builder()
        self.assertIn(1, self.types)
        self.assertEqual(len(self.effects), 2)
        self.assertIn(2, self.effects)
        self.assertEqual(self.effects[2].falloff_attr_id, 20)
        self.assert_log_entries(0)

    def test_duplicate(self):
        self.eff_link1['isDefault'] = True
        self.eff_link2['isDefault'] = True
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        # Make sure effects are not removed
        self.assertEqual(len(self.effects), 2)
        self.assertIn(1, self.effects)
        self.assertIn(2, self.effects)
        self.assertEqual(self.effects[1].falloff_attr_id, 10)
        self.assert_log_entries(1)
        log_record = self.log[0]
        self.assertEqual(log_record.levelno, logging.WARNING)
        self.assertEqual(
            log_record.msg,
            'data contains 1 excessive default effects, '
            'marking them as non-default')

    def test_cleanup(self):
        del self.type['groupID']
        self.eff_link1['isDefault'] = True
        self.eff_link2['isDefault'] = True
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assertEqual(len(self.effects), 0)
        self.assert_log_entries(0)
