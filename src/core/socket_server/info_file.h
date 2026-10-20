#ifndef INFO_FILE_H
#define INFO_FILE_H

#include <stdint.h>
#include <stdio.h>
#include <string>

// 16 hexadecimal characters FNV-1a hash of a name
inline std::string fnv1a_hash_str(std::string const &name) {
  uint64_t hash = 14695981039346656037ULL;
  for (unsigned char c : name) {
    hash = (hash ^ c) * 1099511628211ULL;
  }
  char hash_str[17];
  snprintf(hash_str, sizeof(hash_str), "%016llx", (unsigned long long)hash);
  return hash_str;
}

// path of the info file <prefix><name>.txt of a server/client in info_dir,
// a name too long for a file name (255 bytes) is shortened, with a hash of the full name
inline std::string info_file_path(std::string const &info_dir, std::string const &prefix,
                                  std::string const &name) {
  std::string file = prefix + name + ".txt";
  if (file.size() > 255) {
    file = prefix + name.substr(0, 200) + "_" + fnv1a_hash_str(name) + ".txt";
  }
  return info_dir + "/" + file;
}
#endif
