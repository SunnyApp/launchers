package com.sidlatau.flutteremailsender

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.*
import java.io.File

private const val SUBJECT = "subject"
private const val BODY = "body"
private const val RECIPIENTS = "recipients"
private const val CC = "cc"
private const val BCC = "bcc"
private const val ATTACHMENT_PATH = "attachment_path"
private const val REQUEST_CODE_SEND = 607

class FlutterEmailSenderPlugin(private val registrar: Registrar)
    : MethodCallHandler, ActivityResultListener {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_email_sender")
            val plugin = FlutterEmailSenderPlugin(registrar)
            registrar.addActivityResultListener(plugin)
            channel.setMethodCallHandler(plugin)
        }
    }

    private lateinit var channelResult: Result

    override fun onMethodCall(call: MethodCall, result: Result) {
        this.channelResult = result
        if (call.method == "send") {
            sendEmail(call, result)
        } else {
            result.notImplemented()
        }
    }

    private fun sendEmail(options: MethodCall, callback: Result) {
        val activity = registrar.activity()
        if (activity == null) {
            callback.error("error", "Activity == null!", null)
        }

        val intent = Intent(Intent.ACTION_SEND)


        intent.type = "vnd.android.cursor.dir/email"

        options.string(SUBJECT) {subject->
            intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        }

        options.string(BODY) {body->
            intent.putExtra(Intent.EXTRA_TEXT, body)
        }

        options.strings(RECIPIENTS) {recipients->
            intent.putExtra(Intent.EXTRA_EMAIL, recipients.toTypedArray())
        }

        options.strings(CC) { cc->
            intent.putExtra(Intent.EXTRA_CC, cc.toTypedArray())
        }

        options.strings(BCC) { bcc->
            intent.putExtra(Intent.EXTRA_BCC, bcc.toTypedArray())
        }

        options.string(ATTACHMENT_PATH) { attachmentPath->
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            val file = File(attachmentPath)
            val uri = FileProvider.getUriForFile(activity, registrar.context().packageName + ".file_provider", file)

            intent.putExtra(Intent.EXTRA_STREAM, uri)
        }

        val packageManager = activity.packageManager

        if (packageManager.resolveActivity(intent, 0) != null) {
            activity.startActivityForResult(intent, REQUEST_CODE_SEND)
        } else {
            callback.error("not_available", "No email clients found!", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE_SEND -> {
                when(resultCode) {
                    -1 -> channelResult.success("sent")
                    0 -> channelResult.success("cancelled")
                    else-> channelResult.success("sent")
                }
                return true
            }
            else -> false
        }
    }
}

/**
 * Executes code on a String argument if the argument exists and is non-null
 */
fun MethodCall.string(key:String, block: (String)->Unit) = this.argument<String>(key)?.let(block)

/**
 * Executes code on a List<String> argument if the argument exists and is non-null
 */
fun MethodCall.strings(key:String, block: (List<String>)->Unit) = this.argument<List<String>>(key)?.let(block)
