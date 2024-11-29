import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  List<String> _options = [
    "permission bluetooth granted",
    "bluetooth enabled",
    "connection status",
    "update info"
  ];
  final _localKey = GlobalKey();

  String _selectSize = "2";
  final _txtText = TextEditingController(text: "Hello developer");
  bool _progress = false;
  String _msjprogress = "";

  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> headerData = [
      {'លរ': '000001'},
      {'កាលបរិច្ឆេទ': DateTime.now().toString()},
      {'អ្នកលក់': 'Jhon'},
      {'អតិថជន': 'General'},
      {'លេខទូរស័ព្ទ': 'xxx xxx xxx'}
    ];

    List<String> dataTableHeader = ['ទំនិញ', 'ចំនួន', 'តម្លៃ', 'សរុប'];

    List<Map<String, dynamic>> dataTableBody = [
      {'item': '9-lolipop', 'qty': 10, 'price': 1.5, 'amount': 0},
      {'item': 'Pop-Candy', 'qty': 25, 'price': 2.5, 'amount': 0},
      {'item': 'Cola', 'qty': 50, 'price': 2.5, 'amount': 0},
      {'item': '7up', 'qty': 5, 'price': 1.5, 'amount': 0},
      {'item': 'Pespi', 'qty': 100, 'price': 1.5, 'amount': 0},
    ];
    num total = 0;
    for (int i = 0; i < dataTableBody.length; i++) {
      total += dataTableBody[i]['price'] * dataTableBody[i]['qty'];
    }
    ThemeData theme = Theme.of(context);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            PopupMenuButton(
              elevation: 3.2,
              //initialValue: _options[1],
              onCanceled: () {
                print('You have not chossed anything');
              },
              tooltip: 'Menu',
              onSelected: (Object select) async {
                String sel = select as String;
                if (sel == "permission bluetooth granted") {
                  bool status =
                      await PrintBluetoothThermal.isPermissionBluetoothGranted;
                  setState(() {
                    _info = "permission bluetooth granted: $status";
                  });
                  //open setting permision if not granted permision
                } else if (sel == "bluetooth enabled") {
                  bool state = await PrintBluetoothThermal.bluetoothEnabled;
                  setState(() {
                    _info = "Bluetooth enabled: $state";
                  });
                } else if (sel == "update info") {
                  initPlatformState();
                } else if (sel == "connection status") {
                  final bool result =
                      await PrintBluetoothThermal.connectionStatus;
                  connected = result;
                  setState(() {
                    _info = "connection status: $result";
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return _options.map((String option) {
                  return PopupMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('info: $_info\n '),
                Text(_msj),
                Row(
                  children: [
                    Text("Type print"),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: optionprinttype,
                      items: options.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          optionprinttype = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        this.getBluetoots();
                      },
                      child: Row(
                        children: [
                          Visibility(
                            visible: _progress,
                            child: SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 1,
                                  backgroundColor: Colors.white),
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(_progress ? _msjprogress : "Search"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.disconnect : null,
                      child: Text("Disconnect"),
                    ),
                  ],
                ),
                Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: ListView.builder(
                      itemCount: items.length > 0 ? items.length : 0,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            String mac = items[index].macAdress;
                            this.connect(mac);
                          },
                          title: Text('Name: ${items[index].name}'),
                          subtitle:
                              Text("macAddress: ${items[index].macAdress}"),
                        );
                      },
                    )),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: Column(children: [
                    Text(
                        "Text size without the library without external packets, print images still it should not use a library"),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _txtText,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Text",
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        DropdownButton<String>(
                          hint: Text('Size'),
                          value: _selectSize,
                          items: <String>['1', '2', '3', '4', '5']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: new Text(value),
                            );
                          }).toList(),
                          onChanged: (String? select) {
                            setState(() {
                              _selectSize = select.toString();
                            });
                          },
                        )
                      ],
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.printWithoutPackage : null,
                      child: Text("Print"),
                    ),
                  ]),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: connected ? () => this.printTest() : null,
                      child: Text("Test Image"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: connected
                          ? () => this.printTest(imageRaster: true)
                          : null,
                      child: Text("Test Image Raster"),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                RepaintBoundary(
                  key: _localKey,
                  child: Container(
                    color: Colors.white,
                    child: SizedBox(
                      width: PaperSize.mm80.width.toDouble(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RABBIT',
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            '# Street 153 រ៉ាប៊ីតតិចណូឡូជី, Battambang, Cambodia',
                            style: theme.textTheme.headlineSmall!
                                .copyWith(fontSize: 16.0),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'លេខទូរស័ព្ទ ៖ 070 550 880',
                            style: theme.textTheme.headlineSmall!
                                .copyWith(fontSize: 16.0),
                          ),
                          const Divider(
                            color: Colors.black,
                            thickness: 1.5,
                          ),
                          Text('Invoice',
                              style: theme.textTheme.headlineSmall!.copyWith(
                                  decoration: TextDecoration.underline)),
                          for (int i = 0; i < headerData.length; i++)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  headerData[i].keys.first.toUpperCase(),
                                ),
                                Text(
                                  headerData[i].entries.single.value.toString(),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10.0),
                          SizedBox(
                            width: double.infinity,
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.black),
                              child: DataTable(
                                columnSpacing: 0.0,
                                dividerThickness: 1.5,
                                horizontalMargin: 0.0,
                                showBottomBorder: true,
                                columns: <DataColumn>[
                                  for (int i = 0;
                                      i < dataTableHeader.length;
                                      i++)
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          dataTableHeader[i],
                                          style: theme.textTheme.bodyMedium!
                                              .copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                                rows: <DataRow>[
                                  for (int i = 0; i < dataTableBody.length; i++)
                                    DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          Text(
                                            dataTableBody[i]['item'],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            dataTableBody[i]['qty'].toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            dataTableBody[i]['price']
                                                .toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${dataTableBody[i]['price'] * dataTableBody[i]['qty']}',
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RichText(
                                textAlign: TextAlign.end,
                                text: TextSpan(
                                    text: 'សរុបទាំងអស់ : ',
                                    style: theme.textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                          text: '$total \$',
                                          style: theme.textTheme.titleLarge),
                                    ]),
                              )
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          const Text('សូមអរគុណជួបគ្នាម្តងទៀត...')
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      //print("patformversion: $platformVersion");
      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    print("bluetooth enabled: $result");
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    setState(() {
      _info = platformVersion + " ($porcentbatery% battery)";
    });
  }

  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    /*await Future.forEach(listResult, (BluetoothInfo bluetooth) {
      String name = bluetooth.name;
      String mac = bluetooth.macAdress;
    });*/

    setState(() {
      _progress = false;
    });

    if (listResult.length == 0) {
      _msj =
          "There are no bluetoohs linked, go to settings and link the printer";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("state conected $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

  Future<void> printTest({bool? imageRaster = false}) async {
    /*if (kDebugMode) {
      bool result = await PrintBluetoothThermalWindows.writeBytes(bytes: "Hello \n".codeUnits);
      return;
    }*/

    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      bool result = false;
      // if (Platform.isWindows) {
      //   List<int> ticket = await testWindows();
      //   result = await PrintBluetoothThermalWindows.writeBytes(bytes: ticket);
      // } else {
      List<int> ticket = await testTicket(imageRaster);
      result = await PrintBluetoothThermal.writeBytes(ticket);
      // }
      print("print test result:  $result");
    } else {
      print("print test conexionStatus: $conexionStatus");
      setState(() {
        disconnect();
      });

      //throw Exception("Not device connected");
    }
  }

  Future<void> printString() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    if (conexionStatus) {
      String enter = '\n';
      await PrintBluetoothThermal.writeBytes(enter.codeUnits);
      //size of 1-5
      String text = "Hello";
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 1, text: text));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 2, text: text + " size 2"));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 3, text: text + " size 3"));
    } else {
      //desconectado
      print("desconectado bluetooth $conexionStatus");
    }
  }

  Future<List<int>> testTicket(bool? imageRaster) async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    // final ByteData data = await rootBundle.load('assets/mylogo.jpg');
    // final Uint8List bytesImg = data.buffer.asUint8List();
    // img.Image? image = img.decodeImage(bytesImg);

    final RenderRepaintBoundary boundary =
        _localKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final screenWidth = boundary.size.width;
    double quality = (optionprinttype == "58 mm"
            ? PaperSize.mm58.width
            : PaperSize.mm80.width) /
        screenWidth;
    final toImage = await boundary.toImage(pixelRatio: quality);
    final byteData = await toImage.toByteData(format: ImageByteFormat.png);
    final Uint8List bytesImg = byteData!.buffer.asUint8List();
    // var bs64 = base64.encode(bytesImg);
    // img.Image image = img.decodeImage(base64.decode(bs64))!;
    img.Image image = img.decodeImage(bytesImg)!;

    // if (Platform.isIOS) {
    //   // Resizes the image to half its original size and reduces the quality to 80%
    //   final resizedImage = img.copyResize(image!,
    //       width: image.width ~/ 1.3,
    //       height: image.height ~/ 1.3,
    //       interpolation: img.Interpolation.nearest);
    //   final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
    //   //image = img.decodeImage(bytesimg);
    // }

    if (imageRaster != true) {
      //Using `ESC *`
      bytes += generator.image(image!);
    } else {
      // Using `GS v 0` (obsolete)
      bytes += generator.imageRaster(image);
    }

    // bytes += generator.text(
    //     'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    // bytes += generator.text('Special 1: ñÑ àÀ èÈ éÉ üÜ çÇ ôÔ',
    //     styles: PosStyles(codeTable: 'CP1252'));
    // bytes += generator.text('Special 2: blåbærgrød',
    //     styles: PosStyles(codeTable: 'CP1252'));

    // bytes += generator.text('Bold text', styles: PosStyles(bold: true));
    // bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
    // bytes += generator.text('Underlined text',
    //     styles: PosStyles(underline: true), linesAfter: 1);
    // bytes +=
    //     generator.text('Align left', styles: PosStyles(align: PosAlign.left));
    // bytes += generator.text('Align center',
    //     styles: PosStyles(align: PosAlign.center));
    // bytes += generator.text('Align right',
    //     styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    // bytes += generator.row([
    //   PosColumn(
    //     text: 'col3',
    //     width: 3,
    //     styles: PosStyles(align: PosAlign.center, underline: true),
    //   ),
    //   PosColumn(
    //     text: 'col6',
    //     width: 6,
    //     styles: PosStyles(align: PosAlign.center, underline: true),
    //   ),
    //   PosColumn(
    //     text: 'col3',
    //     width: 3,
    //     styles: PosStyles(align: PosAlign.center, underline: true),
    //   ),
    // ]);

    // //barcode

    // final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    // bytes += generator.barcode(Barcode.upcA(barData));

    // //QR code
    // bytes += generator.qrcode('example.com');

    // bytes += generator.text(
    //   'Text size 50%',
    //   styles: PosStyles(
    //     fontType: PosFontType.fontB,
    //   ),
    // );
    // bytes += generator.text(
    //   'Text size 100%',
    //   styles: PosStyles(
    //     fontType: PosFontType.fontA,
    //   ),
    // );
    // bytes += generator.text(
    //   'Text size 200%',
    //   styles: PosStyles(
    //     height: PosTextSize.size2,
    //     width: PosTextSize.size2,
    //   ),
    // );

    bytes += generator.feed(1);
    bytes += generator.cut();
    return bytes;
  }

  // Future<List<int>> testWindows() async {
  //   List<int> bytes = [];

  //   bytes +=
  //       PostCode.text(text: "Size compressed", fontSize: FontSize.compressed);
  //   bytes += PostCode.text(text: "Size normal", fontSize: FontSize.normal);
  //   bytes += PostCode.text(text: "Bold", bold: true);
  //   bytes += PostCode.text(text: "Inverse", inverse: true);
  //   bytes += PostCode.text(text: "AlignPos right", align: AlignPos.right);
  //   bytes += PostCode.text(text: "Size big", fontSize: FontSize.big);
  //   bytes += PostCode.enter();

  //   //List of rows
  //   bytes += PostCode.row(
  //       texts: ["PRODUCT", "VALUE"],
  //       proportions: [60, 40],
  //       fontSize: FontSize.compressed);
  //   for (int i = 0; i < 3; i++) {
  //     bytes += PostCode.row(
  //         texts: ["Item $i", "$i,00"],
  //         proportions: [60, 40],
  //         fontSize: FontSize.compressed);
  //   }

  //   bytes += PostCode.line();

  //   bytes += PostCode.barcode(barcodeData: "123456789");
  //   bytes += PostCode.qr("123456789");

  //   bytes += PostCode.enter(nEnter: 5);

  //   return bytes;
  // }

  Future<void> printWithoutPackage() async {
    //impresion sin paquete solo de PrintBluetoothTermal
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String text = _txtText.text.toString() + "\n";
      bool result = await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: int.parse(_selectSize), text: text));
      print("status print result: $result");
      setState(() {
        _msj = "printed status: $result";
      });
    } else {
      //no conectado, reconecte
      setState(() {
        _msj = "no connected device";
      });
      print("no conectado");
    }
  }
}
