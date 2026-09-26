package com.registry.app

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

/** The provider stream ended before a complete backup could be read or written. */
class BackupMissingStreamException : IOException(
    "The file provider did not open a stream.",
)

/** More than [maxBytes] were available. Nothing past the limit is kept. */
class BackupTransferLimitException : IOException(
    "The file is larger than the backup limit.",
)

/**
 * Byte copies for a user-selected document.
 *
 * A save writes the new bytes and then sets the destination length. A provider
 * that only overwrites the front of a longer file would otherwise leave trailing
 * bytes. A read stops after one extra byte so an untrusted size cannot force the
 * rest of the file into memory.
 */
object BackupStreams {
    fun writeThenTruncate(
        output: OutputStream,
        bytes: ByteArray,
        truncate: (Long) -> Unit,
    ) {
        output.write(bytes)
        output.flush()
        truncate(bytes.size.toLong())
    }

    fun readAtMost(input: InputStream, maxBytes: Int): ByteArray {
        if (maxBytes < 0) {
            throw IllegalArgumentException("maxBytes")
        }
        val out = ByteArrayOutputStream(minOf(maxBytes, 64 * 1024).coerceAtLeast(0))
        val chunk = ByteArray(16 * 1024)
        var total = 0
        while (total <= maxBytes) {
            val want = minOf(chunk.size, maxBytes + 1 - total)
            if (want <= 0) {
                break
            }
            val read = input.read(chunk, 0, want)
            if (read < 0) {
                break
            }
            if (read == 0) {
                continue
            }
            out.write(chunk, 0, read)
            total += read
        }
        if (total > maxBytes) {
            throw BackupTransferLimitException()
        }
        return out.toByteArray()
    }
}
