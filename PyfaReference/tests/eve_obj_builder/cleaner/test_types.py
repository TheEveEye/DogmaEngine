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


class TestCleanupTypes(EveObjBuilderTestCase):
    """Check which entries should stay in the data."""

    def get_log(self, name='eos.eve_obj_builder.cleaner'):
        return EveObjBuilderTestCase.get_log(self, name=name)

    def test_group_character(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 1})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(clean_stats.msg, 'cleaned: 0.0% from evetypes')

    def test_group_effect_beacon(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 920})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(clean_stats.msg, 'cleaned: 0.0% from evetypes')

    def test_group_other(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(clean_stats.msg, 'cleaned: 100.0% from evetypes')

    def test_group_character_unpublished(self):
        self.dh.data['evetypes'].append(
            {'typeID': 1, 'groupID': 1, 'published': False})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(clean_stats.msg, 'cleaned: 0.0% from evetypes')

    def test_category_ship(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 6})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_module(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 7})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_charge(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 8})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_skill(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 16})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_drone(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 18})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_implant(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 20})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_subsystem(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 32})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_fighter(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 87})
        self.run_builder()
        self.assertEqual(len(self.types), 1)
        self.assertIn(1, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg, 'cleaned: 0.0% from evegroups, 0.0% from evetypes')

    def test_category_other(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 50})
        self.dh.data['evegroups'].append({'groupID': 50, 'categoryID': 51})
        self.run_builder()
        self.assertEqual(len(self.types), 0)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg,
            'cleaned: 100.0% from evegroups, 100.0% from evetypes')

    def test_mixed(self):
        self.dh.data['evetypes'].append({'typeID': 1, 'groupID': 920})
        self.dh.data['evetypes'].append({'typeID': 2, 'groupID': 50})
        self.dh.data['evetypes'].append({'typeID': 3, 'groupID': 20})
        self.dh.data['evegroups'].append({'groupID': 20, 'categoryID': 7})
        self.dh.data['evetypes'].append({'typeID': 4, 'groupID': 80})
        self.dh.data['evegroups'].append({'groupID': 80, 'categoryID': 700})
        self.run_builder()
        self.assertEqual(len(self.types), 2)
        self.assertIn(1, self.types)
        self.assertIn(3, self.types)
        self.assert_log_entries(1)
        clean_stats = self.log[0]
        self.assertEqual(clean_stats.levelno, logging.INFO)
        self.assertEqual(
            clean_stats.msg,
            'cleaned: 50.0% from evegroups, 50.0% from evetypes')
