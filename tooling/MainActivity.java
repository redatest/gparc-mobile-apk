package dz.sonelgaz.gparc_mobile;

import android.media.MediaActionSound;
import android.os.Bundle;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "dz.sonelgaz.gparc_mobile/scanner_sound";
    private MediaActionSound cameraSound;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        cameraSound = new MediaActionSound();
        cameraSound.load(MediaActionSound.SHUTTER_CLICK);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("playShutter".equals(call.method)) {
                    if (cameraSound != null) {
                        cameraSound.play(MediaActionSound.SHUTTER_CLICK);
                    }
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });
    }

    @Override
    protected void onDestroy() {
        if (cameraSound != null) {
            cameraSound.release();
            cameraSound = null;
        }
        super.onDestroy();
    }
}
