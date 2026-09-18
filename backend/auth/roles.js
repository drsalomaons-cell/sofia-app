const ROLES = {
  CENTRAL: 'central_admin',
  REGIONAL: 'regional_admin',
  ROOM_OWNER: 'room_owner',
  MODERATOR: 'moderator',
  PARTICIPANT: 'participant',
};

const REGIONS = ['América do Sul', 'América do Norte', 'Ásia', 'África', 'Global'];

function isCentralAdmin(user) {
  return user?.isAdmin === true || user?.role === ROLES.CENTRAL
    || user?.role === 'ADMIN_CENTRAL' || user?.adminLevel === 'ADMIN_CENTRAL';
}

function isRegionalAdmin(user) {
  return user?.isRegionalAdmin === true || user?.role === ROLES.REGIONAL
    || user?.role === 'ADMIN_REGIONAL' || user?.adminLevel === 'ADMIN_REGIONAL';
}

function canManageRegion(user, region) {
  if (isCentralAdmin(user)) return true;
  if (isRegionalAdmin(user)) return user.region === region;
  return false;
}

function canModerateRoom(user, room) {
  if (isCentralAdmin(user)) return true;
  if (room.hostId === user.id) return true;
  if ((room.moderatorIds || []).includes(user.id)) return true;
  if (isRegionalAdmin(user) && room.region === user.region) return true;
  return false;
}

function roomRole(user, room) {
  if (room.hostId === user.id) return ROLES.ROOM_OWNER;
  if ((room.moderatorIds || []).includes(user.id)) return ROLES.MODERATOR;
  return ROLES.PARTICIPANT;
}

function canTakeSeat(room, seatIndex, userId) {
  const seat = (room.seats || []).find((s) => s.index === seatIndex);
  if (!seat) return false;
  if (seat.isLocked && seat.userId !== userId) return false;
  if (seat.userId && seat.userId !== userId) return false;
  if ((room.bannedUsers || []).includes(userId)) return false;
  return true;
}

module.exports = {
  ROLES,
  REGIONS,
  isCentralAdmin,
  isRegionalAdmin,
  canManageRegion,
  canModerateRoom,
  roomRole,
  canTakeSeat,
};
