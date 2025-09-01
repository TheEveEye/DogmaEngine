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


"""
Some modules, like ballistic control systems, do not affect missile attributes
directly; instead, they affect an attribute on the character, which, in turn,
should affect missiles. In EVE, missile damage effect, when calculating final
damage to deal to target, takes missile damage and multiplies it by value taken
from character. We add special effect instead to help with tracing what affects
what.
"""


from eos.const.eve import TypeGroupId
from eos.eve_obj.type import TypeFactory
from .effect import make_missile_dmg_effect


def add_missile_dmg_effect(item_type):
    if item_type.group_id == TypeGroupId.character:
        missile_dmg_effect = make_missile_dmg_effect()
        item_type.effects[missile_dmg_effect.id] = missile_dmg_effect


TypeFactory.register_instance(add_missile_dmg_effect)
