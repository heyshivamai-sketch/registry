package com.registry.app

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

class BackupStreamsTest {
    @Test
    fun shorterOverwriteDropsTrailingBytes() {
        val file = StickyFile(ByteArray(20) { 0xFF.toByte() })
        val next = byteArrayOf(1, 2, 3, 4)
        BackupStreams.writeThenTruncate(file.sink(), next, file::truncate)
        assertArrayEquals(next, file.data)
    }

    @Test
    fun partialWriteDoesNotReportACompleteFile() {
        val file = StickyFile(ByteArray(8) { 7 })
        val output = object : OutputStream() {
            var written = 0
            override fun write(b: Int) {
                if (written == 2) {
                    throw IOException("write failed")
                }
                file.data[written] = b.toByte()
                written += 1
            }
        }
        assertThrows(IOException::class.java) {
            BackupStreams.writeThenTruncate(output, byteArrayOf(9, 9, 9, 9)) {}
        }
        assertEquals(8, file.data.size)
        assertEquals(7, file.data[3].toInt())
    }

    @Test
    fun oversizedStreamStopsAfterOneExtraByte() {
        val source = CountingInputStream(ByteArrayInputStream(ByteArray(1000) { 1 }))
        assertThrows(BackupTransferLimitException::class.java) {
            BackupStreams.readAtMost(source, 10)
        }
        assertEquals(11, source.consumed)
    }

    @Test
    fun exactFileIsReturnedWithoutAReportedSize() {
        val payload = byteArrayOf(4, 5, 6)
        val source = CountingInputStream(ByteArrayInputStream(payload))
        val read = BackupStreams.readAtMost(source, 10)
        assertArrayEquals(payload, read)
        assertEquals(payload.size, source.consumed)
    }

    private class StickyFile(initial: ByteArray) {
        var data: ByteArray = initial.copyOf()

        fun sink(): OutputStream {
            return object : OutputStream() {
                private var position = 0

                override fun write(b: Int) {
                    if (position == data.size) {
                        data = data.copyOf(data.size + 1)
                    }
                    data[position] = b.toByte()
                    position += 1
                }
            }
        }

        fun truncate(length: Long) {
            data = data.copyOf(length.toInt())
        }
    }

    private class CountingInputStream(private val source: InputStream) : InputStream() {
        var consumed = 0

        override fun read(): Int {
            val value = source.read()
            if (value >= 0) {
                consumed += 1
            }
            return value
        }

        override fun read(b: ByteArray, off: Int, len: Int): Int {
            val count = source.read(b, off, len)
            if (count > 0) {
                consumed += count
            }
            return count
        }
    }
}
