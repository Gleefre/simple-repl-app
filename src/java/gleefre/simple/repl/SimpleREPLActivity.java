package gleefre.simple.repl;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

import android.view.View;
import android.widget.Button;

public class SimpleREPLActivity extends Activity {
  private static Activity currActivity;

  public static Activity getCurrActivity() {
    return currActivity;
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    currActivity = this;

    Button button = new Button(this);
    setContentView(button);

    setupLisp("lib.gleefre.core.so");

    Log.v("ALIEN/GLEEFRE/JAVA", "Simple REPL currently is not running: " + simpleREPLRunning());

    button.setText("Simple REPL is " + (simpleREPLRunning() ? "on" : "off"));
    button.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View v) {
          Log.v("ALIEN/GLEEFRE/JAVA", "In the onClick handler");
          if (!simpleREPLRunning()) {
            Log.v("ALIEN/GLEEFRE/JAVA", "Launching simple REPL");
            launchSimpleREPL();
            Log.v("ALIEN/GLEEFRE/JAVA", "...and done");
            button.setText("Simple REPL is " + (simpleREPLRunning() ? "on" : "off") + " (restarted)");
          } else {
            Log.v("ALIEN/GLEEFRE/JAVA", "Calling onClickLisp");
            onClickLisp();
            Log.v("ALIEN/GLEEFRE/JAVA", "...and done");
            button.setText("Simple REPL is " + (simpleREPLRunning() ? "on" : "off"));
          }
        }
      });

    Log.v("ALIEN/GLEEFRE/JAVA", "onCreate -- done!");
  }

  public native void initLisp(String path);
  public native void onClickLisp();
  public native void launchSimpleREPL();
  public native boolean simpleREPLRunning();

  public void setupLisp(String coreName) {
    String corePath = getApplicationInfo().nativeLibraryDir;
    String coreFullName = corePath + "/" + coreName;
    Log.v("ALIEN/GLEEFRE/JAVA", "Core file is at " + coreFullName);
    initLisp(coreFullName);
    Log.v("ALIEN/GLEEFRE/JAVA", "Lisp initialized");
  }

  static {
    System.loadLibrary(".gleefre.wrap");
  }
}
