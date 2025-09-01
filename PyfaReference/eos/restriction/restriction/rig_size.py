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


from collections import namedtuple

from eos.const.eos import Restriction
from eos.const.eve import AttrId
from eos.const.eve import EffectId
from eos.pubsub.message import EffectsStarted
from eos.pubsub.message import EffectsStopped
from eos.restriction.exception import RestrictionValidationError
from .base import BaseRestrictionRegister


RigSizeErrorData = namedtuple(
    'RigSizeErrorData', ('size', 'allowed_size'))


class RigSizeRestrictionRegister(BaseRestrictionRegister):
    """Allow fitting rigs only of matching size relative to ship size.

    Details:
        For validation, rigSize attribute value of item type is taken.
    """

    type = Restriction.rig_size

    def __init__(self, fit):
        self.__fit = fit
        # Container for items which have rig size restriction
        self.__restricted_items = set()
        fit._subscribe(self, self._handler_map.keys())

    def _handle_effects_started(self, msg):
        if (
            EffectId.rig_slot in msg.effect_ids and
            AttrId.rig_size in msg.item._type_attrs
        ):
            self.__restricted_items.add(msg.item)

    def _handle_effects_stopped(self, msg):
        if EffectId.rig_slot in msg.effect_ids:
            self.__restricted_items.discard(msg.item)

    _handler_map = {
        EffectsStarted: _handle_effects_started,
        EffectsStopped: _handle_effects_stopped}

    def validate(self):
        # Do not apply restriction when fit doesn't have ship and when ship
        # doesn't have restriction attribute
        try:
            allowed_rig_size = self.__fit.ship._type_attrs[AttrId.rig_size]
        except (AttributeError, KeyError):
            return
        tainted_items = {}
        for item in self.__restricted_items:
            rig_size = item._type_attrs[AttrId.rig_size]
            # If rig size specification on item and ship differs, then item is
            # tainted
            if rig_size != allowed_rig_size:
                tainted_items[item] = RigSizeErrorData(
                    size=rig_size,
                    allowed_size=allowed_rig_size)
        if tainted_items:
            raise RestrictionValidationError(tainted_items)
