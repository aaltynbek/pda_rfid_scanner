package com.pda_rfid_scanner;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.reactivex.subjects.PublishSubject;

import java.math.BigInteger;
import java.io.IOException;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.pda_rfid_scanner.utils.LFUtil;

/** PdaRfidScannerPlugin */
public class PdaRfidScannerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native
  /// Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine
  /// and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private EventChannel.EventSink _eventSink;
  protected static LFUtil lfUtil = null;
  static PublishSubject<String> subject = PublishSubject.create();

  public static void registerWith(Registrar registrar) {

  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "pda_rfid_scanner");
    channel.setMethodCallHandler(this);

    new EventChannel(flutterPluginBinding.getBinaryMessenger(), "pda_rfid_scanner/stream")
        .setStreamHandler(new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object args, final EventChannel.EventSink events) {
            subject.subscribe(l -> events.success(l));
          }

          @Override
          public void onCancel(Object args) {
          }
        });
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("setPowerOn")) {
      lfUtil.powerOn();
      lfOpen();
      result.success("on");
    } else if (call.method.equals("setPowerOff")) {
      lfUtil.powerOff();
      lfClose();
      result.success("off");
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    // binding.getActivity()
    // binding.getLifecycle()
    lfUtil = new LFUtil(data -> binding.getActivity().runOnUiThread(() -> onDataReceived(data)));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }

  private void lfOpen() {
    try {
      this.lfUtil.open();
    } catch (Exception e) {
    }
  }

  private void lfClose() {
    try {
      this.lfUtil.close();
    } catch (IOException e) {
      e.printStackTrace();
    }

  }

  /**
   * 接收低频卡数据
   *
   * @param data
   */
  protected static void onDataReceived(final byte[] data) {
    try {
      byte[] id = new byte[64];
      System.arraycopy(data, 0, id, 0, data.length);
      if ((data.length >= 20) & (id[19] == 35)) {
        byte[] temp = new byte[15];
        System.arraycopy(id, 2, temp, 0, 15);
        String str = new String(temp, "ascii");
        // mReception.append(str + "\n");
        subject.onNext(str + "\n");
      } else {
        if (data.length < 30) {
          return;
        }
        int start = -1, end = -1;
        for (int i = 0; i < data.length; i++) {
          if (data[i] == 0x02) {
            start = i;
          } else if (data[i] == 0x03) {// FDX
            end = i;
            break;
          } else if (data[i] == 0x07) {// HDX
            end = i;
            break;
          }
        }
        if (start == -1 || end == -1) {
          return;
        }
        byte[] tempBuffer = new byte[14];
        System.arraycopy(data, start + 1, tempBuffer, 0, tempBuffer.length);

        String rawString = new String(tempBuffer, "ascii");
        String idStr = new BigInteger(rev(rawString.substring(0, 10)), 16).toString(10);
        idStr = paddingLeft(idStr, 12, "0");
        String countCodeStr = new BigInteger(rev(rawString.substring(10, 13)), 16).toString(10);
        subject.onNext(countCodeStr + idStr + "\n");
        // mReception.append(countCodeStr + idStr + "\n");
      }

    } catch (Exception e) {
      // Log.e(TAG, "Exception: " + e.getMessage());
    }
  }

  private static String rev(String ox) {
    byte[] b = ox.getBytes();
    int j = 0;
    byte[] result = new byte[b.length];
    int i = b.length - 1;
    while (i >= 0) {
      result[j] = b[i];
      i--;
      j++;
    }
    return new String(result);
  }

  private static String paddingLeft(String rawString, int len, String fillChar) {
    StringBuilder stringBuilder = new StringBuilder();
    int fillLen = len - rawString.length();
    if (fillLen <= 0)
      return rawString;
    while (fillLen-- > 0) {
      stringBuilder.append(fillChar);
    }
    stringBuilder.append(rawString);
    return stringBuilder.toString();
  }
}