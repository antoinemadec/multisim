#ifndef SOCKET_IO_H
#define SOCKET_IO_H

#include <errno.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

// send/read a whole message on a stream socket: like send()/read() when nothing was transferred
// (e.g. EAGAIN on a non-blocking socket), otherwise wait for the rest of the message so that the
// stream stays aligned on messages, a peer gone in the middle of a message is returned as 0
static inline ssize_t socket_wait_and_retry(int fd, short events, size_t done, ssize_t r) {
  if (done == 0) {
    return r;
  }
  if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)) {
    struct pollfd pfd = {fd, events, 0};
    poll(&pfd, 1, -1);
    return 1;
  }
  return 0;
}

static inline ssize_t send_msg(int fd, const void *buf, size_t size) {
  size_t done = 0;
  while (done < size) {
    ssize_t r = send(fd, (const char *)buf + done, size - done, MSG_NOSIGNAL);
    if (r > 0) {
      done += r;
    } else if ((r = socket_wait_and_retry(fd, POLLOUT, done, r)) <= 0) {
      return r;
    }
  }
  return done;
}

static inline ssize_t read_msg(int fd, void *buf, size_t size) {
  size_t done = 0;
  while (done < size) {
    ssize_t r = read(fd, (char *)buf + done, size - done);
    if (r > 0) {
      done += r;
    } else if ((r = socket_wait_and_retry(fd, POLLIN, done, r)) <= 0) {
      return r;
    }
  }
  return done;
}
#endif
