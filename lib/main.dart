import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';

void main() => runApp(MaterialApp(
      home: Home(),
      debugShowCheckedModeBanner: false,
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList = [];
  int _lastRemovedPos;
  Map<String, dynamic> _lastRemoved;

  //@override sobreescrever método
  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    if (isEmail(_toDoController.text)) {
      setState(() {
        Map<String, dynamic> newToDo = Map();
        newToDo['title'] = _toDoController.text;
        _toDoController.text = '';
        _toDoList.add(newToDo);
        _saveData();
      });
    } else {
      _showDialog('Aviso', 'Preencha com E-mail Válido !');
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      //orderna list
      _toDoList.sort((a, b) {
        return a['title'].toLowerCase().compareTo(b['title'].toLowerCase());
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de E-mail"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 1, 17),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Nova E-mail",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                    controller: _toDoController,
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Salvar"),
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _addToDo();
                      _toDoController.text = '';
                      FocusScope.of(context).requestFocus(new FocusNode());
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.redAccent,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: ListTile(
        title: Text(_toDoList[index]['title']),
        trailing: RaisedButton(
          //trailing right , leading left
          color: Colors.green,
          child: Text(
            "Enviar",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            _launchURL(_toDoList[index]['title']);
          },
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          final Snack = SnackBar(
            content: Text("E-mail ${_lastRemoved['title']} removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).showSnackBar(Snack);
        });
      },
    );
  }

  //open email
  _launchURL(String email) async {
    String url = "mailto:$email?subject=Title&body=Text";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

//retorna arquivo
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/emails.json");
  }

//salvar
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

//ler documentos
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: new Text(title),
          content: new Text(message),
          actions: <Widget>[
            // define os botões na base do dialogo
            new FlatButton(
              child: new Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
