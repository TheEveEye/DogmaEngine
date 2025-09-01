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


from eos.const.eos import State
from eos.const.eve import AttrId
from eos.item import Drone
from eos.pubsub.message import StatesActivatedLoaded
from eos.pubsub.message import StatesDeactivatedLoaded
from .base import BaseResourceRegister


class DroneBandwidthRegister(BaseResourceRegister):

    def __init__(self, fit):
        BaseResourceRegister.__init__(self)
        self.__fit = fit
        self.__resource_users = set()
        fit._subscribe(self, self._handler_map.keys())

    @property
    def used(self):
        return sum(
            item.attrs[AttrId.drone_bandwidth_used]
            for item in self.__resource_users)

    @property
    def output(self):
        try:
            return self.__fit.ship.attrs[AttrId.drone_bandwidth]
        except (AttributeError, KeyError):
            return 0

    @property
    def _users(self):
        return self.__resource_users

    def _handle_states_activated_loaded(self, msg):
        if (
            isinstance(msg.item, Drone) and
            State.online in msg.states and
            AttrId.drone_bandwidth_used in msg.item._type_attrs
        ):
            self.__resource_users.add(msg.item)

    def _handle_states_deactivated_loaded(self, msg):
        if isinstance(msg.item, Drone) and State.online in msg.states:
            self.__resource_users.discard(msg.item)

    _handler_map = {
        StatesActivatedLoaded: _handle_states_activated_loaded,
        StatesDeactivatedLoaded: _handle_states_deactivated_loaded}
