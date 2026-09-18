const store = require('../data/store');

function initRoomSocket(io) {
  io.on('connection', (socket) => {
    socket.on('room:join', ({ roomId, userId, userName }) => {
      socket.join(roomId);
      socket.data.roomId = roomId;
      socket.data.userId = userId;
      socket.to(roomId).emit('room:user_joined', { userId, userName });
      const room = store.findRoom(roomId);
      if (room) socket.emit('room:state', { room });
    });

    socket.on('room:leave', ({ roomId, userId }) => {
      socket.leave(roomId);
      socket.to(roomId).emit('room:user_left', { userId });
    });

    socket.on('room:chat', (payload) => {
      const { roomId, message } = payload;
      io.to(roomId).emit('room:chat', message);
    });

    socket.on('room:gift', (payload) => {
      const { roomId } = payload;
      io.to(roomId).emit('room:gift', payload);
    });

    socket.on('room:seat_update', (payload) => {
      const { roomId } = payload;
      io.to(roomId).emit('room:seat_update', payload);
    });

    socket.on('room:mic_toggle', (payload) => {
      const { roomId } = payload;
      io.to(roomId).emit('room:mic_toggle', payload);
    });

    socket.on('rtc:signal', (payload) => {
      const { roomId, targetUserId, signal } = payload;
      if (targetUserId) {
        io.to(roomId).except(socket.id).emit('rtc:signal', {
          fromUserId: socket.data.userId,
          targetUserId,
          signal,
        });
      } else {
        socket.to(roomId).emit('rtc:signal', {
          fromUserId: socket.data.userId,
          signal,
        });
      }
    });

    socket.on('disconnect', () => {
      const { roomId, userId } = socket.data;
      if (roomId && userId) {
        socket.to(roomId).emit('room:user_left', { userId });
      }
    });
  });
}

module.exports = { initRoomSocket };
