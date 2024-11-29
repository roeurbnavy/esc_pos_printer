// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';
// // import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
// import 'package:image/image.dart' as img;
// import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     checConnection();
//   }

//   bool connected = false;
//   List availableBluetoothDevices = [];
//   final _localKey = GlobalKey();

//   Future<void> getBluetooth() async {
//     final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
//     setState(() {
//       availableBluetoothDevices = bluetooths!;
//     });
//   }

//   Future<void> checConnection() async {
//     String? conn = await BluetoothThermalPrinter.connectionStatus;

//     if (conn == "true") {
//       setState(() {
//         connected = true;
//       });
//     }
//   }

//   Future<void> setConnect(String mac) async {
//     final String? result = await BluetoothThermalPrinter.connect(mac);
//     print("state conneected $result");
//     if (result == "true") {
//       setState(() {
//         connected = true;
//       });
//     }
//   }

//   Future<void> printTicket() async {
//     String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//     if (isConnected == "true") {
//       List<int> bytes = await getTicket();
//       final result = await BluetoothThermalPrinter.writeBytes(bytes);
//       print("Print $result");
//     } else {
//       //Hadnle Not Connected Senario
//     }
//   }

//   Future<void> printGraphics() async {
//     String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//     if (isConnected == "true") {
//       List<int> bytes = await getGraphicsTicket();
//       final result = await BluetoothThermalPrinter.writeBytes(bytes);
//       print("Print $result");
//     } else {
//       //Hadnle Not Connected Senario
//     }
//   }

//   Future<List<int>> getGraphicsTicket() async {
//     List<int> bytes = [];

//     CapabilityProfile profile = await CapabilityProfile.load();
//     final generator = Generator(PaperSize.mm80, profile);

//     // Print QR Code using native function
//     bytes += generator.qrcode('example.com');

//     bytes += generator.hr();

//     // Print Barcode using native function
//     final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
//     bytes += generator.barcode(Barcode.upcA(barData));

//     bytes += generator.cut();

//     return bytes;
//   }

//   Future<List<int>> getTicket() async {
//     List<int> bytes = [];
//     // Using default profile
//     final profile = await CapabilityProfile.load();
//     final generator = Generator(PaperSize.mm80, profile);
//     //bytes += generator.setGlobalFont(PosFontType.fontA);
//     bytes += generator.reset();

//     // final ByteData data = await rootBundle.load('assets/mylogo.jpg');
//     // final Uint8List bytesImg = data.buffer.asUint8List();
//     // final img.Image? image = img.decodeImage(bytesImg);

//     final RenderRepaintBoundary boundary =
//         _localKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

//     final screenWidth = boundary.size.width;
//     double quality = (PaperSize.mm80.width) / screenWidth;
//     final toImage = await boundary.toImage(pixelRatio: quality);
//     final byteData = await toImage.toByteData(format: ImageByteFormat.png);
//     final Uint8List bytesImg = byteData!.buffer.asUint8List();
//     // var bs64 = base64.encode(bytesImg);
//     // img.Image image = img.decodeImage(base64.decode(bs64))!;
//     img.Image image = img.decodeImage(bytesImg)!;

//     // Convert to grayscal
//     img.Image grayscal = img.grayscale(image);

//     // Resize to the printer's width (e.q 384 dots)
//     img.Image resize = img.copyResize(
//       grayscal,
//       width: grayscal.width,
//     ); // width: 384

//     // Convert to 1-bit monochrome (black and white)
//     for (int y = 0; y < resize.height; y++) {
//       for (int x = 0; x < resize.width; x++) {
//         int pixel = resize.getPixel(x, y);
//         int gray = img.getLuminance(pixel);
//         resize.setPixel(x, y,
//             gray < 128 ? img.getColor(0, 0, 0) : img.getColor(255, 255, 255));
//       }
//     }

//     // Convert the monochrome to raster data
//     int widthBytes = (resize.width + 7) ~/ 8;
//     Uint8List rasterData = Uint8List(widthBytes * resize.height);

//     for (int y = 0; y < resize.height; y++) {
//       for (int x = 0; x < resize.width; x++) {
//         int pixcel = resize.getPixel(x, y);
//         int bit = (pixcel == img.getColor(0, 0, 0))
//             ? 1
//             : 0; // Blcak pixcel = 1, white =0
//         rasterData[(y * widthBytes + (x ~/ 8))] |= (bit << (7 - (x % 8)));
//       }
//     }
//     bytes.addAll([
//       // 0x1D, 0x76, 0x30, 0x00, // GS v 0 command
//       // rasterData.length ~/ 8, // xL (width in bytes)
//       // 0x00, // xH
//       // rasterData.length % 256, // yL (height in dots, low byte)
//       // rasterData.length ~/ 256, // yH (height in dots, high byte)
//       0x1D, 0x76, 0x30, 0x00, // GS v 0 command
//       widthBytes & 0xFF, // xL: Width of the image in bytes (low byte)
//       (widthBytes >> 8) & 0xFF, // xH: Width of the image in bytes (high byte)
//       resize.height & 0xFF, // yL: Height of the image in pixels (low byte)
//       (resize.height >> 8) &
//           0xFF, // yH: Height of the image in pixels (high byte)
//       ...rasterData
//     ]);

//     // if (Platform.isIOS) {
//     // // Resizes the image to half its original size and reduces the quality to 80%
//     // final resizedImage = img.copyResize(image!,
//     //     width: image.width ~/ 1.3,
//     //     height: image.height ~/ 1.3,
//     //     interpolation: img.Interpolation.nearest);
//     // final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
//     // // image = img.decodeImage(bytesimg);
//     // }
//     // print('image.width ~/ 1.3 ==== ${image!.width} ${image!.width ~/ 1.3}');
//     // print('image.height ~/ 1.3 ==== ${image!.height} ${image.height ~/ 1.3}');

//     //Using `ESC *`
//     // bytes += generator.image(image);
//     // Using `GS v 0` (obsolete)
//     bytes += generator.imageRaster(image);
// // // Using `GS ( L`
// //     bytes += generator.imageRaster(image,
// //         imageFn: PosImageFn.bitImageRaster); // , imageFn: PosImageFn.graphics

//     // bytes += generator.text(
//     //     'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
//     // bytes += generator.text('Special 1: ñÑ àÀ èÈ éÉ üÜ çÇ ôÔ',
//     //     styles: PosStyles(codeTable: 'CP1252'));
//     // bytes += generator.text('Special 2: blåbærgrød',
//     //     styles: PosStyles(codeTable: 'CP1252'));

//     // bytes += generator.text('Bold text', styles: PosStyles(bold: true));
//     // bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
//     // bytes += generator.text('Underlined text',
//     //     styles: PosStyles(underline: true), linesAfter: 1);
//     // bytes +=
//     //     generator.text('Align left', styles: PosStyles(align: PosAlign.left));
//     // bytes += generator.text('Align center',
//     //     styles: PosStyles(align: PosAlign.center));
//     // bytes += generator.text('Align right',
//     //     styles: PosStyles(align: PosAlign.right), linesAfter: 1);

//     // bytes += generator.row([
//     //   PosColumn(
//     //     text: 'col3',
//     //     width: 3,
//     //     styles: PosStyles(align: PosAlign.center, underline: true),
//     //   ),
//     //   PosColumn(
//     //     text: 'col6',
//     //     width: 6,
//     //     styles: PosStyles(align: PosAlign.center, underline: true),
//     //   ),
//     //   PosColumn(
//     //     text: 'col3',
//     //     width: 3,
//     //     styles: PosStyles(align: PosAlign.center, underline: true),
//     //   ),
//     // ]);

//     // //barcode

//     // final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
//     // bytes += generator.barcode(Barcode.upcA(barData));

//     // //QR code
//     // bytes += generator.qrcode('example.com');

//     // bytes += generator.text(
//     //   'Text size 50%',
//     //   styles: PosStyles(
//     //     fontType: PosFontType.fontB,
//     //   ),
//     // );
//     // bytes += generator.text(
//     //   'Text size 100%',
//     //   styles: PosStyles(
//     //     fontType: PosFontType.fontA,
//     //   ),
//     // );
//     // bytes += generator.text(
//     //   'Text size 200%',
//     //   styles: PosStyles(
//     //     height: PosTextSize.size2,
//     //     width: PosTextSize.size2,
//     //   ),
//     // );

//     // bytes += generator.feed(1);
//     bytes += generator.cut();
//     return bytes;
//   }

//   // Future<List<int>> getTicket() async {
//   //   List<int> bytes = [];
//   //   CapabilityProfile profile = await CapabilityProfile.load();
//   //   final generator = Generator(PaperSize.mm80, profile);

//   //   bytes += generator.text("Demo Shop",
//   //       styles: PosStyles(
//   //         align: PosAlign.center,
//   //         height: PosTextSize.size2,
//   //         width: PosTextSize.size2,
//   //       ),
//   //       linesAfter: 1);

//   //   bytes += generator.text(
//   //       "18th Main Road, 2nd Phase, J. P. Nagar, Bengaluru, Karnataka 560078",
//   //       styles: PosStyles(align: PosAlign.center));
//   //   bytes += generator.text('Tel: +919591708470',
//   //       styles: PosStyles(align: PosAlign.center));

//   //   bytes += generator.hr();
//   //   bytes += generator.row([
//   //     PosColumn(
//   //         text: 'No',
//   //         width: 1,
//   //         styles: PosStyles(align: PosAlign.left, bold: true)),
//   //     PosColumn(
//   //         text: 'Item',
//   //         width: 5,
//   //         styles: PosStyles(align: PosAlign.left, bold: true)),
//   //     PosColumn(
//   //         text: 'Price',
//   //         width: 2,
//   //         styles: PosStyles(align: PosAlign.center, bold: true)),
//   //     PosColumn(
//   //         text: 'Qty',
//   //         width: 2,
//   //         styles: PosStyles(align: PosAlign.center, bold: true)),
//   //     PosColumn(
//   //         text: 'សរុប',
//   //         containsChinese: true,
//   //         width: 2,
//   //         styles: PosStyles(align: PosAlign.right, bold: true)),
//   //   ]);

//   //   bytes += generator.row([
//   //     PosColumn(text: "1", width: 1),
//   //     PosColumn(
//   //         text: "Tea",
//   //         width: 5,
//   //         styles: PosStyles(
//   //           align: PosAlign.left,
//   //         )),
//   //     PosColumn(
//   //         text: "10",
//   //         width: 2,
//   //         styles: PosStyles(
//   //           align: PosAlign.center,
//   //         )),
//   //     PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
//   //     PosColumn(text: "10", width: 2, styles: PosStyles(align: PosAlign.right)),
//   //   ]);

//   //   bytes += generator.row([
//   //     PosColumn(text: "2", width: 1),
//   //     PosColumn(
//   //         text: "Sada Dosa",
//   //         width: 5,
//   //         styles: PosStyles(
//   //           align: PosAlign.left,
//   //         )),
//   //     PosColumn(
//   //         text: "30",
//   //         width: 2,
//   //         styles: PosStyles(
//   //           align: PosAlign.center,
//   //         )),
//   //     PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
//   //     PosColumn(text: "30", width: 2, styles: PosStyles(align: PosAlign.right)),
//   //   ]);

//   //   bytes += generator.row([
//   //     PosColumn(text: "3", width: 1),
//   //     PosColumn(
//   //         text: "Masala Dosa",
//   //         width: 5,
//   //         styles: PosStyles(
//   //           align: PosAlign.left,
//   //         )),
//   //     PosColumn(
//   //         text: "50",
//   //         width: 2,
//   //         styles: PosStyles(
//   //           align: PosAlign.center,
//   //         )),
//   //     PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
//   //     PosColumn(text: "50", width: 2, styles: PosStyles(align: PosAlign.right)),
//   //   ]);

//   //   bytes += generator.row([
//   //     PosColumn(text: "4", width: 1),
//   //     PosColumn(
//   //         text: "Rova Dosa",
//   //         width: 5,
//   //         styles: PosStyles(
//   //           align: PosAlign.left,
//   //         )),
//   //     PosColumn(
//   //         text: "70",
//   //         width: 2,
//   //         styles: PosStyles(
//   //           align: PosAlign.center,
//   //         )),
//   //     PosColumn(text: "1", width: 2, styles: PosStyles(align: PosAlign.center)),
//   //     PosColumn(text: "70", width: 2, styles: PosStyles(align: PosAlign.right)),
//   //   ]);

//   //   bytes += generator.hr();

//   //   bytes += generator.row([
//   //     PosColumn(
//   //         text: 'TOTAL',
//   //         width: 6,
//   //         styles: PosStyles(
//   //           align: PosAlign.left,
//   //           height: PosTextSize.size4,
//   //           width: PosTextSize.size4,
//   //         )),
//   //     PosColumn(
//   //         text: "160",
//   //         width: 6,
//   //         styles: PosStyles(
//   //           align: PosAlign.right,
//   //           height: PosTextSize.size4,
//   //           width: PosTextSize.size4,
//   //         )),
//   //   ]);

//   //   bytes += generator.hr(ch: '=', linesAfter: 1);

//   //   // ticket.feed(2);
//   //   bytes += generator.text('Thank you!',
//   //       styles: PosStyles(align: PosAlign.center, bold: true));

//   //   bytes += generator.text("26-11-2020 15:22:45",
//   //       styles: PosStyles(align: PosAlign.center), linesAfter: 1);

//   //   bytes += generator.text(
//   //       'Note: Goods once sold will not be taken back or exchanged.',
//   //       styles: PosStyles(align: PosAlign.center, bold: false));
//   //   bytes += generator.cut();
//   //   return bytes;
//   // }

//   @override
//   Widget build(BuildContext context) {
//     List<Map<String, dynamic>> headerData = [
//       {'លរ': '000001'},
//       {'កាលបរិច្ឆេទ': DateTime.now().toString()},
//       {'អ្នកលក់': 'Jhon'},
//       {'អតិថជន': 'General'},
//       {'លេខទូរស័ព្ទ': 'xxx xxx xxx'}
//     ];

//     List<String> dataTableHeader = ['ទំនិញ', 'ចំនួន', 'តម្លៃ', 'សរុប'];

//     List<Map<String, dynamic>> dataTableBody = [
//       {'item': '9-lolipop', 'qty': 10, 'price': 1.5, 'amount': 0},
//       {'item': 'Pop-Candy', 'qty': 25, 'price': 2.5, 'amount': 0},
//       {'item': 'Cola', 'qty': 50, 'price': 2.5, 'amount': 0},
//       {'item': '7up', 'qty': 5, 'price': 1.5, 'amount': 0},
//       {'item': 'Pespi', 'qty': 100, 'price': 1.5, 'amount': 0},
//     ];
//     num total = 0;
//     for (int i = 0; i < dataTableBody.length; i++) {
//       total += dataTableBody[i]['price'] * dataTableBody[i]['qty'];
//     }
//     ThemeData theme = Theme.of(context);

//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Bluetooth Thermal Printer Demo'),
//         ),
//         body: SingleChildScrollView(
//           child: Container(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Connection status $connected"),
//                 SizedBox(
//                   height: 10,
//                 ),
//                 Text("Search Paired Bluetooth"),
//                 TextButton(
//                   onPressed: () {
//                     this.getBluetooth();
//                   },
//                   child: Text("Search"),
//                 ),
//                 Container(
//                   height: 200,
//                   child: ListView.builder(
//                     itemCount: availableBluetoothDevices.length > 0
//                         ? availableBluetoothDevices.length
//                         : 0,
//                     itemBuilder: (context, index) {
//                       return ListTile(
//                         onTap: () {
//                           String select = availableBluetoothDevices[index];
//                           print('select ===== $select');
//                           List list = select.split("#");
//                           // String name = list[0];
//                           String mac = list[1];
//                           this.setConnect(mac);
//                         },
//                         title: Text('${availableBluetoothDevices[index]}'),
//                         subtitle: Text("Click to connect"),
//                       );
//                     },
//                   ),
//                 ),
//                 SizedBox(
//                   height: 30,
//                 ),
//                 RepaintBoundary(
//                   key: _localKey,
//                   child: Container(
//                     color: Colors.white,
//                     child: SizedBox(
//                       width: PaperSize.mm80.width.toDouble(),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'RABBIT',
//                             style: theme.textTheme.headlineMedium,
//                           ),
//                           Text(
//                             '# Street 153 រ៉ាប៊ីតតិចណូឡូជី, Battambang, Cambodia',
//                             style: theme.textTheme.headlineSmall!
//                                 .copyWith(fontSize: 16.0),
//                             textAlign: TextAlign.center,
//                           ),
//                           Text(
//                             'លេខទូរស័ព្ទ ៖ 070 550 880',
//                             style: theme.textTheme.headlineSmall!
//                                 .copyWith(fontSize: 16.0),
//                           ),
//                           const Divider(
//                             color: Colors.black,
//                             thickness: 1.5,
//                           ),
//                           Text('Invoice',
//                               style: theme.textTheme.headlineSmall!.copyWith(
//                                   decoration: TextDecoration.underline)),
//                           for (int i = 0; i < headerData.length; i++)
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   headerData[i].keys.first.toUpperCase(),
//                                 ),
//                                 Text(
//                                   headerData[i].entries.single.value.toString(),
//                                 ),
//                               ],
//                             ),
//                           const SizedBox(height: 10.0),
//                           SizedBox(
//                             width: double.infinity,
//                             child: Theme(
//                               data: Theme.of(context)
//                                   .copyWith(dividerColor: Colors.black),
//                               child: DataTable(
//                                 columnSpacing: 0.0,
//                                 dividerThickness: 1.5,
//                                 horizontalMargin: 0.0,
//                                 showBottomBorder: true,
//                                 columns: <DataColumn>[
//                                   for (int i = 0;
//                                       i < dataTableHeader.length;
//                                       i++)
//                                     DataColumn(
//                                       label: Expanded(
//                                         child: Text(
//                                           dataTableHeader[i],
//                                           style: theme.textTheme.bodyMedium!
//                                               .copyWith(
//                                                   fontStyle: FontStyle.italic,
//                                                   fontWeight: FontWeight.bold),
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                                 rows: <DataRow>[
//                                   for (int i = 0; i < dataTableBody.length; i++)
//                                     DataRow(
//                                       cells: <DataCell>[
//                                         DataCell(
//                                           Text(
//                                             dataTableBody[i]['item'],
//                                           ),
//                                         ),
//                                         DataCell(
//                                           Text(
//                                             dataTableBody[i]['qty'].toString(),
//                                           ),
//                                         ),
//                                         DataCell(
//                                           Text(
//                                             dataTableBody[i]['price']
//                                                 .toString(),
//                                           ),
//                                         ),
//                                         DataCell(
//                                           Text(
//                                             '${dataTableBody[i]['price'] * dataTableBody[i]['qty']}',
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 10.0),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               RichText(
//                                 textAlign: TextAlign.end,
//                                 text: TextSpan(
//                                     text: 'សរុបទាំងអស់ : ',
//                                     style: theme.textTheme.bodyMedium,
//                                     children: [
//                                       TextSpan(
//                                           text: '$total \$',
//                                           style: theme.textTheme.titleLarge),
//                                     ]),
//                               )
//                             ],
//                           ),
//                           const SizedBox(height: 10.0),
//                           const Text('សូមអរគុណជួបគ្នាម្តងទៀត...')
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: connected ? this.printGraphics : null,
//                   child: Text("Print"),
//                 ),
//                 TextButton(
//                   onPressed: connected ? this.printTicket : null,
//                   child: Text("Print Ticket"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
