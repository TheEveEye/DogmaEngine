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


from eos.const.eve import AttrId
from eos.const.eos import EosTypeId
from eos.const.eos import ModAffecteeFilter
from eos.const.eos import ModAggregateMode
from eos.const.eos import ModDomain
from eos.const.eos import ModOperator
from eos.eve_obj.modifier import DogmaModifier


def make_missile_rof_modifiers():
    modifiers = []
    modifiers.append(DogmaModifier(
        affectee_filter=ModAffecteeFilter.domain_skillrq,
        affectee_filter_extra_arg=EosTypeId.current_self,
        affectee_domain=ModDomain.ship,
        affectee_attr_id=AttrId.speed,
        operator=ModOperator.post_percent,
        aggregate_mode=ModAggregateMode.stack,
        affector_attr_id=AttrId.rof_bonus))
    return modifiers


def make_missile_dmg_modifiers(affectee_attr_id):
    modifiers = []
    modifiers.append(DogmaModifier(
        affectee_filter=ModAffecteeFilter.owner_skillrq,
        affectee_filter_extra_arg=EosTypeId.current_self,
        affectee_domain=ModDomain.character,
        affectee_attr_id=affectee_attr_id,
        operator=ModOperator.post_percent,
        aggregate_mode=ModAggregateMode.stack,
        affector_attr_id=AttrId.dmg_mult_bonus))
    return modifiers


def make_drone_dmg_modifiers():
    modifiers = []
    modifiers.append(DogmaModifier(
        affectee_filter=ModAffecteeFilter.owner_skillrq,
        affectee_filter_extra_arg=EosTypeId.current_self,
        affectee_domain=ModDomain.character,
        affectee_attr_id=AttrId.dmg_mult,
        operator=ModOperator.post_percent,
        aggregate_mode=ModAggregateMode.stack,
        affector_attr_id=AttrId.dmg_mult_bonus))
    return modifiers
