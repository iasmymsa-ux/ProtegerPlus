package com.example.proteger_plus

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Canal nativo de emergência — usado pelo EmergencyService do Flutter
    private val CHANNEL = "com.protegerplus/emergency"
    private val SMS_PERMISSION_CODE = 1001
    private var pendingPermissionResult: MethodChannel.Result? = null

    // Referência explícita a R.raw.alarme para garantir que AAPT e R8 nunca descartem o recurso de som
    private val keepAlarmSoundRes = R.raw.alarme

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        setupAlarmNotificationChannel()
    }

    private fun setupAlarmNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                // Remove canais antigos obsoletos para garantir que som e vibração sejam recriados com prioridade máxima
                val oldChannels = listOf(
                    "lembretes_alarme_sonoro_v21",
                    "lembretes_alarme_alto_v10",
                    "lembretes_alarme_sonoro_v6",
                    "lembretes_alarme_sonoro",
                    "lembretes_alarme"
                )
                for (oldId in oldChannels) {
                    try {
                        notificationManager.deleteNotificationChannel(oldId)
                    } catch (_: Exception) {}
                }

                val channelId = "lembretes_alarme_proteger_v30"
                val channelName = "Alarmes e Lembretes Proteger+"
                val channelDesc = "Alarmes de alta prioridade com som audível e vibração forte para medicamentos, consultas e tarefas"
                val importance = NotificationManager.IMPORTANCE_HIGH

                val channel = NotificationChannel(channelId, channelName, importance).apply {
                    description = channelDesc
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000)
                    enableLights(true)
                    lightColor = android.graphics.Color.RED
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC

                    val soundUri = Uri.parse("android.resource://$packageName/raw/alarme")
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                        .build()
                    setSound(soundUri, audioAttributes)
                    setBypassDnd(true)
                }

                notificationManager.createNotificationChannel(channel)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Erro ao registrar canal de alarme nativo: ${e.message}")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "hasSmsPermission" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this, Manifest.permission.SEND_SMS
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }

                    "requestSmsPermission" -> {
                        if (ContextCompat.checkSelfPermission(
                                this, Manifest.permission.SEND_SMS
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(true)
                        } else {
                            pendingPermissionResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.SEND_SMS),
                                SMS_PERMISSION_CODE
                            )
                        }
                    }

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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
