package gleefre.simple.repl;

import android.app.Activity;
import android.os.Bundle;

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
    
    button.setText("Simple REPL is " + (simpleREPLRunning() ? "on" : "off"));
    button.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View v) {
          if (!simpleREPLRunning()) {
            launchSimpleREPL();
          } else {
            onClickLisp();
          }
          button.setText("Simple REPL is " + (simpleREPLRunning() ? "on" : "off"));
        }
      });
  }

  public native void initLisp(String path);
  public native void onClickLisp();
  public native void launchSimpleREPL();
  public native boolean simpleREPLRunning();

  public void setupLisp(String coreName) {
    String corePath = getApplicationInfo().nativeLibraryDir;
    String coreFullName = corePath + "/" + coreName;
    initLisp(coreFullName);
  }

  static {
    System.loadLibrary(".gleefre.wrap");
  }
}
