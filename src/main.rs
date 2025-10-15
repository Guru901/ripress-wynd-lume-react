use std::env;

use lume::{
    database::{Database, error::DatabaseError},
    define_schema,
};
use ripress::{app::App, types::RouterFns};
use wynd::wynd::{WithRipress, Wynd};

define_schema! {
    Users {
        id: u64,
        name: String,
        email: String,
        password: String,
    }
}

#[tokio::main]
async fn main() -> Result<(), DatabaseError> {
    dotenv::dotenv().ok();
    let mut wynd: Wynd<WithRipress> = Wynd::new();
    let mut app = App::new();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    let db = Database::connect(&database_url).await?;

    db.register_table::<Users>().await?;

    db.insert(Users {
        id: 1,
        name: "John Doe".to_string(),
        email: "john.doe@example.com".to_string(),
        password: "password".to_string(),
    })
    .execute()
    .await?;

    app.static_files("/", "./dist").unwrap();

    wynd.on_connection(|conn| async move {
        println!("Client connected: {:?}", conn.id());

        conn.on_text(|event, handle| async move {
            if event.data == "get_users" {
                let users = get_users().await;
                handle.send_text(&users.join(",")).await.unwrap();
            } else {
                handle.broadcast.emit_text(&event.data).await;
            }
        });
    });

    app.get("/hello", |_, res| async {
        return res.text("Hello from Ripress!");
    });

    app.get("/users", |_, res| async {
        let users = get_users().await;
        res.ok().json(&users)
    });

    app.use_wynd("/ws", wynd.handler());

    app.listen(3000, || {
        println!("listening on http://localhost:3000");
    })
    .await;

    Ok(())
}

async fn get_users() -> Vec<String> {
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    let db = Database::connect(&database_url).await.unwrap();

    let users = db
        .query::<Users, SelectUsers>()
        .select(SelectUsers::selected().name())
        .execute()
        .await
        .unwrap();

    let user_names = users
        .iter()
        .map(|user| user.get(Users::name()).unwrap())
        .collect::<Vec<String>>();

    user_names
}
