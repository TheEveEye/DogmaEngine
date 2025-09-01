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


import math

from eos.eve_obj.attribute import Attribute
from eos.eve_obj.effect import Effect
from eos.eve_obj.type import AbilityData
from eos.eve_obj.type import Type
from .buff_template_builder import WarfareBuffTemplateBuilder
from .mod_builder import ModBuilder


class Converter:

    @staticmethod
    def run(data):
        """Convert data into eve objects.

        Args:
            data: Dictionary in {table name: {table, rows}} format.

        Returns:
            4 iterables, which contain types, attributes, effects and warfare
            buff templates.
        """
        # Before actually instantiating anything, we need to collect some data
        # in convenient form
        # Format: {group ID: group row}
        groups_keyed = {}
        for row in data['evegroups']:
            groups_keyed[row['groupID']] = row
        # Format: {type ID: default effect ID}
        types_defeff_map = {}
        for row in data['dgmtypeeffects']:
            if row.get('isDefault') is True:
                types_defeff_map[row['typeID']] = row['effectID']
        # Format: {type ID: {effect IDs}}
        types_effects = {}
        for row in data['dgmtypeeffects']:
            types_effects.setdefault(row['typeID'], set()).add(row['effectID'])
        # Format: {type ID: {attribute ID: value}}
        types_attrs = {}
        for row in data['dgmtypeattribs']:
            type_attrs = types_attrs.setdefault(row['typeID'], {})
            type_attrs[row['attributeID']] = row['value']
        # Format: {type ID: {ability ID: (cooldown, charge quantity)}}
        types_abilities_data = {}
        for row in data['typefighterabils']:
            type_id = row['typeID']
            type_abilities_data = types_abilities_data.setdefault(type_id, {})
            type_abilities_data[row['abilityID']] = AbilityData(
                cooldown_time=row.get('cooldownSeconds', 0),
                charge_quantity=row.get('chargeCount', math.inf))
        # Format: {type ID: {skill type ID: level}}
        types_skillreq_data = {}
        for row in data['skillreqs']:
            type_skillreq_data = types_skillreq_data.setdefault(row['typeID'], {})
            type_skillreq_data[row['skillTypeID']] = row['level']

        # Convert attributes
        attrs = []
        for row in data['dgmattribs']:
            attrs.append(Attribute(
                attr_id=row['attributeID'],
                max_attr_id=row.get('maxAttributeID'),
                default_value=row.get('defaultValue'),
                high_is_good=row.get('highIsGood'),
                stackable=row.get('stackable')))

        # Convert effects
        effects = []
        mod_builder = ModBuilder()
        for row in data['dgmeffects']:
            modifiers, build_status = mod_builder.build(row)
            effects.append(Effect(
                effect_id=row['effectID'],
                category_id=row.get('effectCategory'),
                is_offensive=row.get('isOffensive'),
                is_assistance=row.get('isAssistance'),
                duration_attr_id=row.get('durationAttributeID'),
                discharge_attr_id=row.get('dischargeAttributeID'),
                range_attr_id=row.get('rangeAttributeID'),
                falloff_attr_id=row.get('falloffAttributeID'),
                tracking_speed_attr_id=row.get('trackingSpeedAttributeID'),
                fitting_usage_chance_attr_id=(
                    row.get('fittingUsageChanceAttributeID')),
                resist_attr_id=row.get('resistanceAttributeID'),
                build_status=build_status,
                modifiers=tuple(modifiers)))

        # Convert types
        types = []
        effect_map = {e.id: e for e in effects}
        for row in data['evetypes']:
            type_id = row['typeID']
            type_group = row.get('groupID')
            type_effect_ids = types_effects.get(type_id, set())
            type_effect_ids.intersection_update(effect_map)
            types.append(Type(
                type_id=type_id,
                group_id=type_group,
                category_id=groups_keyed.get(type_group, {}).get('categoryID'),
                attrs=types_attrs.get(type_id, {}),
                effects=tuple(effect_map[eid] for eid in type_effect_ids),
                default_effect=effect_map.get(types_defeff_map.get(type_id)),
                abilities_data=types_abilities_data.get(type_id, {}),
                required_skills=types_skillreq_data.get(type_id)))

        # Convert buff templates
        buff_templates = []
        for row in data['dbuffcollections']:
            buff_templates.extend(WarfareBuffTemplateBuilder.build(row))

        return types, attrs, effects, buff_templates
