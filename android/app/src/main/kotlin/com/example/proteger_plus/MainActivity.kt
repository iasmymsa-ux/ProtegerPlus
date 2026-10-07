package com.example.proteger_plus

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Canal nativo de emergência — usado pelo EmergencyService do Flutter
    private val CHANNEL = "com.protegerplus/emergency"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Envia SMS diretamente via SmsManager (sem abrir nenhum app)
                    "sendSmsDirectly" -> {
                        val number = call.argument<String>("number") ?: ""
                        val message = call.argument<String>("message") ?: ""

                        if (number.isEmpty() || message.isEmpty()) {
                            result.error("INVALID_ARGS", "Número ou mensagem vazio.", null)
                            return@setMethodCallHandler
                        }

                        // Verifica permissão SEND_SMS em runtime
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
                            != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error(
                                "PERMISSION_DENIED",
                                "Permissão SEND_SMS não concedida. Por favor, conceda a permissão nas configurações do app.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                // API 31+: usa o método de instância via contexto
                                getSystemService(SmsManager::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getDefault()
                            }

                            // Divide mensagens longas automaticamente em várias partes
                            val parts = smsManager.divideMessage(message)
                            if (parts.size == 1) {
                                smsManager.sendTextMessage(number, null, message, null, null)
                            } else {
                                smsManager.sendMultipartTextMessage(number, null, parts, null, null)
                            }

                            result.success("SMS_SENT")
                        } catch (e: Exception) {
                            result.error("SMS_ERROR", e.message ?: "Erro desconhecido ao enviar SMS.", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
