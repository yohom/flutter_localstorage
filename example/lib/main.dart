import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Localstorage Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class TodoItem {
  String title;
  bool done;

  TodoItem({this.title, this.done});

  toJSONEncodable() {
    Map<String, dynamic> m = new Map();

    m['title'] = title;
    m['done'] = done;

    return m;
  }
}

class TodoList {
  List<TodoItem> items;

  TodoList() {
    items = new List();
  }

  toJSONEncodable() {
    return items.map((item) {
      return item.toJSONEncodable();
    }).toList();
  }
}

class _MyHomePageState extends State<HomePage> {
  final TodoList list = new TodoList();
  final LocalStorage storage = new LocalStorage('todo_app');
  bool initialized = false;
  TextEditingController controller = new TextEditingController();

  _toggleItem(TodoItem item) {
    setState(() {
      item.done = !item.done;
      _saveToStorage();
    });
  }

  _addItem(String title) {
    setState(() {
      final item = new TodoItem(title: title, done: false);
      list.items.add(item);
      _saveToStorage();
    });
  }

  _saveToStorage() {
    storage.setItem('todos', list.toJSONEncodable());
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Localstorage demo'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: FutureBuilder(
              future: storage.ready,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.data == null) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!initialized) {
                  var items = storage.getItem('todos');

                  if (items != null) {
                    (items as List).forEach((item) {
                      final todoItem = new TodoItem(
                          title: item['title'], done: item['done']);
                      list.items.add(todoItem);
                    });
                  }

                  initialized = true;
                }

                List<Widget> widgets = list.items.map((item) {
                  return CheckboxListTile(
                    value: item.done,
                    title: Text(item.title),
                    selected: item.done,
                    onChanged: (bool selected) {
                      _toggleItem(item);
                    },
                  );
                }).toList();

                return ListView(
                  children: widgets,
                  itemExtent: 50.0,
                );
              },
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Watch storage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Flexible(
                  child: FutureBuilder(
                    future: storage.ready,
                    builder: (context, snapshot) {
                      return StreamBuilder(
                        stream: storage.watchItem('todos'),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Offstage();
                          return ListView(
                            children: (snapshot.data as List).map((item) {
                              return new TodoItem(
                                title: item['title'],
                                done: item['done'],
                              );
                            }).map((item) {
                              return CheckboxListTile(
                                value: item.done,
                                title: Text(item.title),
                                selected: item.done,
                                onChanged: null,
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'What to do?',
            ),
            onEditingComplete: () {
              _addItem(controller.value.text);
              controller.clear();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    LocalStorage.close();
    super.dispose();
  }
}
