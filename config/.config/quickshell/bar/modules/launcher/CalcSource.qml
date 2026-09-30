import QtQuick
import Quickshell
import Quickshell.Io

// Calculator behind the "=" prefix: evaluates `expr` with qalc shortly after typing stops.
Scope {
    id: root

    property string expr
    // Result for `expr`; "" while it is still being worked out.
    property string result

    onExprChanged: {
        result = "";
        debounce.restart();
    }

    function run(): void {
        if (proc.running || expr.trim() === "")
            return;
        proc.expr = expr;
        proc.running = true;
    }

    Timer {
        id: debounce

        interval: 80
        onTriggered: root.run()
    }

    Process {
        id: proc

        property string expr

        // "--" so an expression starting with a minus isn't read as an option.
        command: ["qalc", "-t", "--", expr]
        stdout: StdioCollector {
            onStreamFinished: {
                // The expression moved on while qalc ran: drop this result and go again.
                if (proc.expr === root.expr)
                    root.result = text.trim();
            }
        }
        onExited: {
            if (expr !== root.expr)
                root.run();
        }
    }
}
