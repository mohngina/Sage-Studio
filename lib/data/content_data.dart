import '../models/service_model.dart';
import '../models/testimonial_model.dart';

class ContentData {
  static const String studioName = "Sage Studio";
  static const String location = "Kamakis, Ruiru, Kenya";
  static const String studioHeadquarters = "Kamakis, Ruiru";
  static const String email = "sagestudio.ke@gmail.com";
  static const String phone = "+254 794 001715";
  static const String studioHours = "Monday – Friday: 09:00 – 17:00 EAT (By private appointment only)";

  static const String studioTagline = "DESIGNED INTENTIONALLY. CRAFTED BEAUTIFULLY.";
  static const String studioSubheading =
      "We are a furniture design studio based in Nairobi, Kenya. Our designs are inspired by contemporary African proportions.";

  static const List<String> newsTickerItems = [
    "NEW COLLECTION 2025 RELEASED",
    "THE BOSIBORI SOFA NOW AVAILABLE",
    "CUSTOM FURNITURE COMMISSIONS OPEN",
    "STUDIO VISITS BY PRIVATE APPOINTMENT IN RUIRU",
  ];

  static const String founderTitle = "Our Story";
  static const String founderSubtitle = "MADE FOR BEAUTIFULLY LIVED SPACES";
  static const String founderBioShort =
      "At Sage, we believe the spaces we live in quietly shape the way we experience life.";
  static const String founderBioFull =
      "At Sage, we believe the spaces we live in quietly shape the way we experience life. What began as a passion for creating beautiful furniture has grown into a deeper pursuit, designing pieces that bring warmth, comfort, and intention into everyday living.\n\nWe create furniture not simply to fill spaces, but to transform them into places of connection, rest, and beautiful moments.\n\nEvery Sage piece is thoughtfully crafted with an appreciation for detail, quality craftsmanship, and the belief that home should feel like an extension of who you are.\n\nMore than furniture, Sage is about creating spaces people genuinely love coming back to.\n\nDesigned intentionally. Crafted beautifully. Made for beautifully lived spaces.";

  static const String founderEssay =
      "The Story Behind Sage\n\nSage began with my own home and a desire to create spaces that felt as good as they looked.\n\nWhen furnishing my space, I discovered that a home is about more than beautiful furniture. It is about the feeling a space creates, the memories it holds and the way it welcomes you back, day after day. That experience shaped my approach to design and became the foundation of Sage Studio.\n\nThe first Sage piece, the Bosibori Sofa, was designed for me. I wanted something that offered comfort, character and a sense of belonging. Today, that same thinking guides how I approach every design, balancing function, form, materials and the individuality of the people who will live with each piece.\n\nI draw inspiration from the richness of African culture, craftsmanship and the stories embedded in the things we create. Through Sage, I hope to reinterpret these influences into thoughtful furniture and interiors that feel personal, enduring and beautifully lived in.\n\nBosibori Maureen\nFounder & Creative Director, Sage Studio";

  static const String founderImage = "assets/images/founder/founder_portrait.jpg";

  // Verbatim 8-Point Info Centre Terms from Brand Specification
  static const List<String> infoCentreItems = [
    "All our sofa cushion are spring based, in the case you want simple cushion or fibre that is available, or indicated",
    "We have various types of fabrics to choose from.",
    "Production timeline is 4 - 8 weeks, but could vary.",
    "70% is required to process your order and 30% balance to be paid upon delivery.",
    "Design changes will incur extra charges.",
    "Customized designs or measurements will incur different prices depending on the design and/or measurements.",
    "Prices on catalog are based on the measurements stated and/or fabric and wood type",
    "Prices on the products exclude delivery charges",
  ];

  static const List<StudioService> services = [
    StudioService(
      id: 's1',
      title: 'Furniture Design & Production',
      subtitle: 'Crafted Around Your Space',
      category: 'BESPOKE FURNITURE',
      description:
          'Every piece we create begins with an idea, shaped by thoughtful design and brought to life through skilled craftsmanship. Work with Sage Studio to create bespoke furniture tailored to your space, aesthetic and functional needs. From proportions and upholstery to timber finishes and detailing, every element is considered.',
      deliverables: [
        'Design consultation and spatial measurements',
        'Custom furniture dimensions and design specifications',
        'Fabric, upholstery and timber finish selection',
        'Cushion and comfort configuration',
        '3D design visualisation where applicable',
        'Furniture production, quality inspection and delivery',
      ],
      image: 'assets/images/products/hero_sofa.jpg',
    ),
    StudioService(
      id: 's2',
      title: 'Interior Design Consult',
      subtitle: 'Spaces Designed to Be Experienced',
      category: 'INTERIOR DESIGN',
      description:
          'We create considered interiors that balance aesthetics, functionality and the way you live or work. From individual room transformations to complete residential and commercial projects, our approach brings together spatial planning, material selection, furniture and carefully curated details to create cohesive, enduring spaces.',
      deliverables: [
        'Initial design consultation and project brief',
        'Space planning and furniture layout',
        'Concept development and mood boards',
        'Colour palettes and material specifications',
        'Furniture, lighting and décor selection',
        '2D layouts and 3D visualisations',
        'Design presentation and project recommendations',
      ],
      image: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1000&q=80',
    ),
    StudioService(
      id: 's3',
      title: 'Interior Design Consult',
      subtitle: 'Thoughtful Design, Wherever You Are',
      category: 'DIGITAL INTERIOR DESIGN',
      description:
          "Bring your space to life with a personalized digital interior design experience. Whether you're furnishing a new home or refreshing an existing space, we help you make confident design decisions through considered layouts, curated furniture selections and cohesive visual concepts.",
      deliverables: [
        'Virtual design consultation and project brief',
        'Digital space planning and 2D/3D room layouts',
        'Curated mood boards, colour palettes and material direction',
        'Sage Studio furniture and décor recommendations',
        'Digital design presentation and consultation via email or video',
      ],
      image: 'https://images.unsplash.com/photo-1615066390971-03e4e1c36ddf?auto=format&fit=crop&w=1000&q=80',
    ),
  ];

  static const List<Testimonial> testimonials = [
    Testimonial(
      id: 't1',
      name: 'Amina Wambui',
      role: 'Homeowner, Karen Nairobi',
      rating: 5.0,
      quote:
          'The BOSIBORI sofa is stunning! The spring cushions provide incredible comfort and the contemporary African proportion fits our living room seamlessly.',
      date: '02.20.25',
    ),
    Testimonial(
      id: 't2',
      name: 'David Ochieng',
      role: 'Architectural Director, Nairobi Studio',
      rating: 5.0,
      quote:
          'Sage Studio produces the highest quality custom furniture in Kenya. Their attention to detail, fabric variety, and wood joinery is world class.',
      date: '01.15.25',
    ),
  ];
}
