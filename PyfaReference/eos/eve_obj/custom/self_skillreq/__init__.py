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


from logging import getLogger

from eos.const.eos import EffectBuildStatus
from eos.const.eve import AttrId
from eos.const.eve import EffectId
from eos.eve_obj.effect import EffectFactory
from .modifier import make_drone_dmg_modifiers
from .modifier import make_missile_dmg_modifiers
from .modifier import make_missile_rof_modifiers


logger = getLogger(__name__)


def add_missile_rof_modifiers(effect):
    if effect.modifiers:
        msg = 'missile self skillreq rof effect has modifiers, overwriting them'
        logger.warning(msg)
    effect.modifiers = make_missile_rof_modifiers()
    effect.build_status = EffectBuildStatus.custom


def _add_missile_dmg_modifiers(effect, attr_id):
    if effect.modifiers:
        msg = f'missile self skillreq damage effect {effect.id} has modifiers, overwriting them'
        logger.warning(msg)
    effect.modifiers = make_missile_dmg_modifiers(attr_id)
    effect.build_status = EffectBuildStatus.custom


def add_missile_dmg_modifiers_em(effect):
    _add_missile_dmg_modifiers(effect, AttrId.em_dmg)


def add_missile_dmg_modifiers_therm(effect):
    _add_missile_dmg_modifiers(effect, AttrId.therm_dmg)


def add_missile_dmg_modifiers_kin(effect):
    _add_missile_dmg_modifiers(effect, AttrId.kin_dmg)


def add_missile_dmg_modifiers_expl(effect):
    _add_missile_dmg_modifiers(effect, AttrId.expl_dmg)


def add_drone_dmg_modifiers(effect):
    if effect.modifiers:
        msg = 'drone self skillreq dmg effect has modifiers, overwriting them'
        logger.warning(msg)
    effect.modifiers = make_drone_dmg_modifiers()
    effect.build_status = EffectBuildStatus.custom


EffectFactory.register_instance_by_id(
    add_missile_rof_modifiers,
    EffectId.self_rof)
EffectFactory.register_instance_by_id(
    add_missile_dmg_modifiers_em,
    EffectId.missile_em_dmg_bonus)
EffectFactory.register_instance_by_id(
    add_missile_dmg_modifiers_therm,
    EffectId.missile_therm_dmg_bonus)
EffectFactory.register_instance_by_id(
    add_missile_dmg_modifiers_kin,
    EffectId.missile_kin_dmg_bonus2)
EffectFactory.register_instance_by_id(
    add_missile_dmg_modifiers_expl,
    EffectId.missile_expl_dmg_bonus)
EffectFactory.register_instance_by_id(
    add_drone_dmg_modifiers,
    EffectId.drone_dmg_bonus)
