import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  final String initialComment;

  const ReviewDialog({this.initialComment = ''});

  @override
  _ReviewDialogState createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialComment;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:Colors.transparent,
      child: Container(
        decoration:BoxDecoration(
          color:Color(0xFFC0C0C0),
          border:Border.all(color:Colors.black),
          boxShadow:[
            BoxShadow(color:Colors.white, offset:Offset(-2,-2), blurRadius:0),
            BoxShadow(color:Colors.black, offset:Offset(2,2), blurRadius:0),
          ],
        ),
        child:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            Container(
              color:Colors.deepOrange,
              padding:EdgeInsets.symmetric(horizontal:4, vertical:2),
              child:Row(
                children:[
                  Expanded(child:Text('Write/Edit Review', style:TextStyle(color:Colors.white, fontSize:12))),
                  GestureDetector(
                    onTap:() => Navigator.pop(context),
                    child:Icon(Icons.close, color:Colors.white, size:12),
                  ),
                ],
              ),
            ),
            Padding(
              padding:EdgeInsets.all(8.0),
              child:Column(
                mainAxisSize:MainAxisSize.min,
                crossAxisAlignment:CrossAxisAlignment.stretch,
                children:[
                  Text('Your Review:', style:TextStyle(color:Colors.black, fontSize:14)),
                  SizedBox(height:8),
                  Container(
                    decoration:BoxDecoration(
                      border:Border.all(color:Colors.black),
                      color:Color(0xFFF4F4F4),
                    ),
                    child:TextField(
                      controller:_controller,
                      maxLines:5,
                      style:TextStyle(color:Colors.black),
                      decoration:InputDecoration(
                        border:InputBorder.none,
                        contentPadding:EdgeInsets.all(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height:8),
                  Row(
                    mainAxisAlignment:MainAxisAlignment.end,
                    children:[
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:MaterialStateProperty.all(Color(0xFFD24407)),
                          elevation:MaterialStateProperty.all(0),
                          side:MaterialStateProperty.all(BorderSide(color:Colors.black, width:2)),
                        ),
                        onPressed:() {
                          Navigator.pop(context, _controller.text);
                        },
                        child:Text('OK', style:TextStyle(color:Colors.white)),
                      ),
                      SizedBox(width:8),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:MaterialStateProperty.all(Color(0xFFD24407)),
                          elevation:MaterialStateProperty.all(0),
                          side:MaterialStateProperty.all(BorderSide(color:Colors.black, width:2)),
                        ),
                        onPressed:() => Navigator.pop(context,null),
                        child:Text('Cancel', style:TextStyle(color:Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
