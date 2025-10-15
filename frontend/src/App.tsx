import { useEffect, useState } from "react";

function App() {
  const [hello, setHello] = useState<string>("");
  const [input, setInput] = useState("");
  const [ws, setWs] = useState<WebSocket>();
  const [messages, setMessages] = useState<string[]>([]);
  const [users, setUsers] = useState<string[]>([]);

  useEffect(() => {
    (async () => {
      const response = await fetch("/api/hello");
      const usersResponse = await fetch("/api/users");
      const ws = new WebSocket("ws://localhost:3000/ws");

      if (!response.ok) {
        throw new Error("Failed to fetch");
      }

      const data = await response.text();
      const usersData = await usersResponse.json();

      setHello(data);
      setUsers(usersData);

      ws.onopen = () => {
        console.log("WebSocket connected");
        setWs(ws);
      };

      ws.onmessage = (event) => {
        setMessages((prev) => [...prev, event.data]);
      };
    })();

    return () => {
      if (ws) {
        ws.close();
      }
    };
  }, []);

  return (
    <div style={{ padding: 24, fontFamily: "system-ui, sans-serif" }}>
      <h1>Ripress + Wynd + React minimal demo</h1>
      <div>
        <h2>/hello</h2>
        <pre>{hello ?? "Loading..."}</pre>
      </div>
      <div>
        <p>Users:</p>
        <ul style={{ listStyle: "none", padding: 0 }}>
          {users.map((user, index) => (
            <li key={index}>{user}</li>
          ))}
        </ul>
      </div>
      <div>
        <h2>Websocket</h2>
        <input
          type="text"
          placeholder="Type something..."
          onChange={(e) => setInput(e.target.value)}
        />
        <button onClick={() => ws?.send(input)}>Send</button>

        <p>Messages:</p>
        <ul style={{ listStyle: "none", padding: 0 }}>
          {messages.map((message, index) => (
            <li key={index}>{message}</li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export default App;
