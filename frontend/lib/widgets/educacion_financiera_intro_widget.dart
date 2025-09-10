import 'package:flutter/material.dart';

class EducacionFinancieraIntroWidget extends StatefulWidget {
  final VoidCallback onContinue;
  final bool isMobile;

  const EducacionFinancieraIntroWidget({
    Key? key,
    required this.onContinue,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<EducacionFinancieraIntroWidget> createState() => _EducacionFinancieraIntroWidgetState();
}

class _EducacionFinancieraIntroWidgetState extends State<EducacionFinancieraIntroWidget> {
  int currentStep = 0;
  
  final List<Map<String, dynamic>> introSteps = [
    {
      'title': '¿Por Qué la Educación Financiera es Fundamental?',
      'content': 'La educación financiera no es solo sobre dinero. Es la base de todas tus decisiones empresariales, desde contratar personal hasta expandir tu negocio. Sin estos fundamentos, estás navegando a ciegas.',
      'buttonText': 'SIGUIENTE',
    },
    {
      'title': '¿Sabías que...?',
      'content': 'Estadísticas que te harán reflexionar sobre la importancia de la educación financiera en el éxito empresarial.',
      'buttonText': 'VER ESTADÍSTICAS',
    },
    {
      'title': 'Lo Que Aprenderás',
      'content': 'Descubre las habilidades fundamentales que transformarán tu forma de manejar tu negocio.',
      'buttonText': 'COMENZAR MI TRANSFORMACIÓN',
    },
  ];

  void _nextStep() {
    if (currentStep < introSteps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      widget.onContinue();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

       @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(widget.isMobile ? 16 : 24),
       child: SingleChildScrollView(
         child: Column(
           children: [
                           // Header elegante
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(widget.isMobile ? 32 : 48),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withAlpha((255 * 0.05).round()),
                     blurRadius: 20,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
               child: Column(
                 children: [
                   // Logo institucional
                   Container(
                                        width: widget.isMobile ? 60 : 80,
                   height: widget.isMobile ? 60 : 80,
                     decoration: BoxDecoration(
                       color: const Color(0xFF1F2937),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Icon(
                       Icons.school,
                       color: Colors.white,
                       size: 32,
                     ),
                   ),
                   const SizedBox(height: 24),
                   
                   // Título principal elegante
                   Text(
                     'EDUCACIÓN FINANCIERA',
                     style: TextStyle(
                       fontSize: widget.isMobile ? 20 : 24,
                       fontWeight: FontWeight.w300,
                       letterSpacing: 2.0,
                       color: const Color(0xFF1F2937),
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 8),
                   
                   // Subtítulo sofisticado
                   Text(
                     'Transforma tu Visión en Realidad Financiera',
                     style: TextStyle(
                       fontSize: widget.isMobile ? 14 : 16,
                       fontWeight: FontWeight.w400,
                       color: const Color(0xFF6B7280),
                       letterSpacing: 0.5,
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 16),
                   
                   // Línea divisoria elegante
                   Container(
                     width: 60,
                     height: 2,
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [
                           const Color(0xFF1F2937),
                           const Color(0xFF6B7280),
                         ],
                       ),
                       borderRadius: BorderRadius.circular(1),
                     ),
                   ),
                 ],
               ),
             ),
                           const SizedBox(height: 24),
              
              // Indicador de progreso
              Container(
                margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 20 : 40),
                child: Row(
                  children: List.generate(introSteps.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= currentStep 
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              
              // Contenido principal
              Container(
               width: double.infinity,
               padding: EdgeInsets.all(widget.isMobile ? 20 : 28),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withAlpha((255 * 0.05).round()),
                     blurRadius: 20,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
                               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de sección
                    Text(
                      introSteps[currentStep]['title'],
                      style: TextStyle(
                        fontSize: widget.isMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Contenido dinámico según el paso
                    _buildStepContent(),
                    
                    const SizedBox(height: 24),
                    
                    // Botones de navegación
                    Row(
                      children: [
                        if (currentStep > 0)
                          Expanded(
                            child: Container(
                              height: widget.isMobile ? 48 : 52,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF1F2937),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _previousStep,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Center(
                                    child: Text(
                                      'ANTERIOR',
                                      style: TextStyle(
                                        fontSize: widget.isMobile ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1F2937),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (currentStep > 0) const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: widget.isMobile ? 48 : 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1F2937),
                                  const Color(0xFF374151),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1F2937).withAlpha((255 * 0.3).round()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _nextStep,
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    introSteps[currentStep]['buttonText'],
                                    style: TextStyle(
                                      fontSize: widget.isMobile ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
             ),
           ],
         ),
       ),
     );
  }

     Widget _buildFeature(String title, String description, IconData icon) {
     return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Container(
           width: 32,
           height: 32,
           decoration: BoxDecoration(
             color: const Color(0xFF1F2937).withAlpha((255 * 0.1).round()),
             borderRadius: BorderRadius.circular(6),
           ),
           child: Icon(
             icon,
             size: 18,
             color: const Color(0xFF1F2937),
           ),
         ),
         const SizedBox(width: 16),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 title,
                 style: TextStyle(
                   fontSize: widget.isMobile ? 15 : 16,
                   fontWeight: FontWeight.w600,
                   color: const Color(0xFF1F2937),
                 ),
               ),
               const SizedBox(height: 4),
               Text(
                 description,
                 style: TextStyle(
                   fontSize: widget.isMobile ? 13 : 14,
                   height: 1.5,
                   color: const Color(0xFF6B7280),
                   fontWeight: FontWeight.w400,
                 ),
               ),
             ],
           ),
         ),
       ],
     );
   }

   Widget _buildStepContent() {
     switch (currentStep) {
       case 0:
         return Text(
           introSteps[currentStep]['content'],
           style: TextStyle(
             fontSize: widget.isMobile ? 15 : 16,
             height: 1.6,
             color: const Color(0xFF4B5563),
             fontWeight: FontWeight.w400,
           ),
         );
       
       case 1:
         return Container(
           padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
           decoration: BoxDecoration(
             color: const Color(0xFFF3F4F6),
             borderRadius: BorderRadius.circular(12),
             border: Border.all(
               color: const Color(0xFFE5E7EB),
               width: 1,
             ),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 introSteps[currentStep]['content'],
                 style: TextStyle(
                   fontSize: widget.isMobile ? 14 : 15,
                   height: 1.5,
                   color: const Color(0xFF4B5563),
                   fontWeight: FontWeight.w500,
                 ),
               ),
               const SizedBox(height: 16),
               _buildStatistic(
                 '90%',
                 'de los emprendedores fracasan por falta de conocimientos financieros',
               ),
               const SizedBox(height: 8),
               _buildStatistic(
                 '3x',
                 'mayor probabilidad de éxito cuando dominas los fundamentos financieros',
               ),
               const SizedBox(height: 8),
               _buildStatistic(
                 '6 meses',
                 'es el tiempo promedio que toma implementar una base financiera sólida',
               ),
             ],
           ),
         );
       
       case 2:
         return Column(
           children: [
             Text(
               introSteps[currentStep]['content'],
               style: TextStyle(
                 fontSize: widget.isMobile ? 15 : 16,
                 height: 1.6,
                 color: const Color(0xFF4B5563),
                 fontWeight: FontWeight.w400,
               ),
             ),
             const SizedBox(height: 20),
             _buildFeature(
               'Toma Decisiones Inteligentes',
               'Aprende a evaluar oportunidades, calcular riesgos y maximizar el retorno de cada inversión en tu negocio.',
               Icons.psychology,
             ),
             const SizedBox(height: 16),
             _buildFeature(
               'Evita Errores Costosos',
               'Conoce los errores financieros más comunes que llevan al fracaso empresarial y cómo evitarlos desde el inicio.',
               Icons.warning,
             ),
             const SizedBox(height: 16),
             _buildFeature(
               'Escala tu Negocio',
               'Domina los principios de crecimiento sostenible y cómo financiar la expansión de tu empresa.',
               Icons.trending_up,
             ),
             const SizedBox(height: 16),
             _buildFeature(
               'Construye Confianza',
               'Desarrolla la credibilidad financiera necesaria para atraer inversores, clientes y talento.',
               Icons.verified,
             ),
           ],
         );
       
       default:
         return const SizedBox.shrink();
     }
   }

   Widget _buildStatistic(String value, String description) {
     return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
             color: const Color(0xFF1F2937),
             borderRadius: BorderRadius.circular(6),
           ),
           child: Text(
             value,
             style: const TextStyle(
               fontSize: 12,
               fontWeight: FontWeight.w700,
               color: Colors.white,
             ),
           ),
         ),
         const SizedBox(width: 12),
         Expanded(
           child: Text(
             description,
             style: TextStyle(
               fontSize: widget.isMobile ? 13 : 14,
               color: const Color(0xFF4B5563),
               fontWeight: FontWeight.w500,
             ),
           ),
         ),
       ],
     );
   }
}