import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
class Splash extends StatelessWidget {
   Splash({super.key});
  @override
  void goToNextScreen() {
    Get.toNamed(AppRoutes.UML);
  }
  Widget build(BuildContext context) {
   return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/main.png",),fit: BoxFit.fill)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),

            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Image.asset("assets/splashRobo.png"),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0,),
              child: Text(" AI-Powered UML Diagram Generator",textAlign: TextAlign.center,style: GoogleFonts.poppins(fontSize: 32,color: Colors.white,fontWeight: FontWeight.w600,),),
            )
            , Text(" Turn system descriptions into clear, visual UML diagrams using AI and PlantUML.",textAlign: TextAlign.center,style: GoogleFonts.poppins(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w300,),),
                    Spacer(),
                    Padding(
                      padding:EdgeInsets.only(bottom: 30),
                      child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5,vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xff691883),
                borderRadius: BorderRadius.circular(24),
              ),

              child: ElevatedButton(onPressed: (){
                goToNextScreen();
              },
                child: Text("Continue...",style: GoogleFonts.poppins(
                    color: Colors.white,fontSize: 20,fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 2),
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
}
