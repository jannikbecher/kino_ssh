import { Terminal } from "@xterm/xterm";
import { FitAddon } from "xterm-addon-fit";
import "@xterm/xterm/css/xterm.css";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  const xtermEl = document.createElement("div");
  xtermEl.id = "terminal";

  ctx.root.appendChild(xtermEl);

  const terminal = new Terminal({ convertEol: true });
  const fitAddon = new FitAddon();
  terminal.loadAddon(fitAddon);
  terminal.open(xtermEl);
  fitAddon.fit();

  terminal.onData((data) => {
    console.log("User Input", data);
    if (data == "\r") {
      ctx.pushEvent("update_terminal", { data: "\n" });
    } else {
      ctx.pushEvent("update_terminal", { data });
    }
  });

  ctx.handleEvent("update_terminal", ({ data }) => {
    terminal.write(data);
  });
}
