import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Agri Farms'**
  String get appTitle;

  /// Greeting text
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// Hint text for search bar
  ///
  /// In en, this message translates to:
  /// **'Search seeds, tractor, spraying...'**
  String get searchHint;

  /// Section header for services
  ///
  /// In en, this message translates to:
  /// **'Book Services'**
  String get bookServices;

  /// Section header for transport
  ///
  /// In en, this message translates to:
  /// **'Book Transport'**
  String get bookTransport;

  /// Section header for equipment rentals
  ///
  /// In en, this message translates to:
  /// **'Rent Equipment'**
  String get rentEquipment;

  /// Section header for tools
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Button text to view more items
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @rentals.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get rentals;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @myServices.
  ///
  /// In en, this message translates to:
  /// **'My Services'**
  String get myServices;

  /// No description provided for @myTransports.
  ///
  /// In en, this message translates to:
  /// **'My Transports'**
  String get myTransports;

  /// No description provided for @myRentals.
  ///
  /// In en, this message translates to:
  /// **'My Rentals'**
  String get myRentals;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @serviceRequests.
  ///
  /// In en, this message translates to:
  /// **'Service Requests'**
  String get serviceRequests;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @yourVillage.
  ///
  /// In en, this message translates to:
  /// **'Your Village'**
  String get yourVillage;

  /// No description provided for @yourDistrict.
  ///
  /// In en, this message translates to:
  /// **'Your District'**
  String get yourDistrict;

  /// No description provided for @ploughing.
  ///
  /// In en, this message translates to:
  /// **'Ploughing'**
  String get ploughing;

  /// No description provided for @harvesting.
  ///
  /// In en, this message translates to:
  /// **'Harvesting'**
  String get harvesting;

  /// No description provided for @farmWorkers.
  ///
  /// In en, this message translates to:
  /// **'Farm Workers'**
  String get farmWorkers;

  /// No description provided for @droneSpraying.
  ///
  /// In en, this message translates to:
  /// **'Drone Spraying'**
  String get droneSpraying;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @soilTesting.
  ///
  /// In en, this message translates to:
  /// **'Soil Testing'**
  String get soilTesting;

  /// No description provided for @vetCare.
  ///
  /// In en, this message translates to:
  /// **'Vet Care'**
  String get vetCare;

  /// No description provided for @miniTruck.
  ///
  /// In en, this message translates to:
  /// **'Mini Truck'**
  String get miniTruck;

  /// No description provided for @tractorTrolley.
  ///
  /// In en, this message translates to:
  /// **'Tractor Trolley'**
  String get tractorTrolley;

  /// No description provided for @fullTruck.
  ///
  /// In en, this message translates to:
  /// **'Full Truck'**
  String get fullTruck;

  /// No description provided for @tempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempo;

  /// No description provided for @pickupVan.
  ///
  /// In en, this message translates to:
  /// **'Pickup Van'**
  String get pickupVan;

  /// No description provided for @container.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get container;

  /// No description provided for @tractors.
  ///
  /// In en, this message translates to:
  /// **'Tractors'**
  String get tractors;

  /// No description provided for @harvesters.
  ///
  /// In en, this message translates to:
  /// **'Harvesters'**
  String get harvesters;

  /// No description provided for @sprayers.
  ///
  /// In en, this message translates to:
  /// **'Sprayers'**
  String get sprayers;

  /// No description provided for @trolleys.
  ///
  /// In en, this message translates to:
  /// **'Trolleys'**
  String get trolleys;

  /// No description provided for @jcb.
  ///
  /// In en, this message translates to:
  /// **'JCB'**
  String get jcb;

  /// No description provided for @cropAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Crop Advisory'**
  String get cropAdvisory;

  /// No description provided for @fertilizerCalculator.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Calculator'**
  String get fertilizerCalculator;

  /// No description provided for @pesticideCalculator.
  ///
  /// In en, this message translates to:
  /// **'Pesticide Calculator'**
  String get pesticideCalculator;

  /// No description provided for @farmingCalculator.
  ///
  /// In en, this message translates to:
  /// **'Farming Calculator'**
  String get farmingCalculator;

  /// No description provided for @freeSoilTesting.
  ///
  /// In en, this message translates to:
  /// **'Free Soil Testing'**
  String get freeSoilTesting;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @newTractorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'New Tractors Available'**
  String get newTractorsAvailable;

  /// No description provided for @lowRentalRates.
  ///
  /// In en, this message translates to:
  /// **'Low rental rates'**
  String get lowRentalRates;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @checkTodaysRates.
  ///
  /// In en, this message translates to:
  /// **'Check today\'s rates'**
  String get checkTodaysRates;

  /// No description provided for @viewPrices.
  ///
  /// In en, this message translates to:
  /// **'View Prices'**
  String get viewPrices;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @sevenDayForecast.
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get sevenDayForecast;

  /// No description provided for @communityQuestions.
  ///
  /// In en, this message translates to:
  /// **'Community Questions'**
  String get communityQuestions;

  /// No description provided for @equipmentRentals.
  ///
  /// In en, this message translates to:
  /// **'Equipment Rentals'**
  String get equipmentRentals;

  /// No description provided for @browseEquipment.
  ///
  /// In en, this message translates to:
  /// **'Browse Equipment'**
  String get browseEquipment;

  /// No description provided for @nearbyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Nearby Equipment'**
  String get nearbyEquipment;

  /// No description provided for @buySell.
  ///
  /// In en, this message translates to:
  /// **'Buy & Sell'**
  String get buySell;

  /// No description provided for @buySellDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct marketplace for seeds, fertilizers, pesticides, and farm produce. Connect with local farmers and merchants.'**
  String get buySellDesc;

  /// No description provided for @rentEquipmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Access tractors, harvesters, sprayers and more. Rent equipment or list your own to earn extra income.'**
  String get rentEquipmentDesc;

  /// No description provided for @bookServicesLogistics.
  ///
  /// In en, this message translates to:
  /// **'Book Services & Logistics'**
  String get bookServicesLogistics;

  /// No description provided for @bookServicesLogisticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Hire ploughing, harvesting, spraying services. Book transport to take your produce to mandi.'**
  String get bookServicesLogisticsDesc;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Agri Farms'**
  String get welcomeTitle;

  /// No description provided for @enterMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to continue'**
  String get enterMobile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose Role'**
  String get chooseRole;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRole;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @termsPolicy.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept our Terms of Service\nand Privacy Policy'**
  String get termsPolicy;

  /// No description provided for @generalUser.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get generalUser;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get farmer;

  /// No description provided for @listYourAssets.
  ///
  /// In en, this message translates to:
  /// **'Register your Services & Equipment'**
  String get listYourAssets;

  /// No description provided for @listTransport.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get listTransport;

  /// No description provided for @listEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get listEquipment;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarket;

  /// No description provided for @navRentals.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get navRentals;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @noMatchFound.
  ///
  /// In en, this message translates to:
  /// **'No match found for your search'**
  String get noMatchFound;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get perDay;

  /// No description provided for @bookWorkers.
  ///
  /// In en, this message translates to:
  /// **'Book Workers'**
  String get bookWorkers;

  /// No description provided for @operatorIncluded.
  ///
  /// In en, this message translates to:
  /// **'Operator Included'**
  String get operatorIncluded;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get booked;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get jobsCompleted;

  /// No description provided for @bookService.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// No description provided for @rentNow.
  ///
  /// In en, this message translates to:
  /// **'Rent Now'**
  String get rentNow;

  /// No description provided for @driverIncluded.
  ///
  /// In en, this message translates to:
  /// **'Driver Inc.'**
  String get driverIncluded;

  /// No description provided for @withOperatorAvailable.
  ///
  /// In en, this message translates to:
  /// **'With Operator Available'**
  String get withOperatorAvailable;

  /// No description provided for @noOperator.
  ///
  /// In en, this message translates to:
  /// **'No Operator'**
  String get noOperator;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @bookTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Book {vehicleType}'**
  String bookTransportTitle(String vehicleType);

  /// No description provided for @goodsType.
  ///
  /// In en, this message translates to:
  /// **'Goods Type'**
  String get goodsType;

  /// No description provided for @selectGoodsType.
  ///
  /// In en, this message translates to:
  /// **'Select what you want to transport'**
  String get selectGoodsType;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @preferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Time'**
  String get preferredTime;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @totalEstimate.
  ///
  /// In en, this message translates to:
  /// **'Total Estimate'**
  String get totalEstimate;

  /// No description provided for @confirmRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Request'**
  String get confirmRequest;

  /// No description provided for @fillAllDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill all details'**
  String get fillAllDetails;

  /// No description provided for @selectGoodsTypeError.
  ///
  /// In en, this message translates to:
  /// **'Select goods type'**
  String get selectGoodsTypeError;

  /// No description provided for @selectDateError.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDateError;

  /// No description provided for @selectTimeError.
  ///
  /// In en, this message translates to:
  /// **'Select time duration'**
  String get selectTimeError;

  /// No description provided for @selectWorkers.
  ///
  /// In en, this message translates to:
  /// **'Select Workers'**
  String get selectWorkers;

  /// No description provided for @chooseWorkDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose your work duration'**
  String get chooseWorkDuration;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @selectAtLeastOneWorker.
  ///
  /// In en, this message translates to:
  /// **'Select at least one worker'**
  String get selectAtLeastOneWorker;

  /// No description provided for @providerInfo.
  ///
  /// In en, this message translates to:
  /// **'Provider Info'**
  String get providerInfo;

  /// No description provided for @availableWorkers.
  ///
  /// In en, this message translates to:
  /// **'Available: {male} Male, {female} Female'**
  String availableWorkers(int male, int female);

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add Listing'**
  String get addListing;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get addVehicle;

  /// No description provided for @addEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get addEquipment;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location (Village -> District)'**
  String get locationLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionLabel;

  /// No description provided for @submitListing.
  ///
  /// In en, this message translates to:
  /// **'Submit Listing'**
  String get submitListing;

  /// No description provided for @groupDetails.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupDetails;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Labour Group'**
  String get groupNameHint;

  /// No description provided for @selectSkills.
  ///
  /// In en, this message translates to:
  /// **'Select Skills'**
  String get selectSkills;

  /// No description provided for @staffPricing.
  ///
  /// In en, this message translates to:
  /// **'Staff & Pricing'**
  String get staffPricing;

  /// No description provided for @maleWorkers.
  ///
  /// In en, this message translates to:
  /// **'Male Workers'**
  String get maleWorkers;

  /// No description provided for @femaleWorkers.
  ///
  /// In en, this message translates to:
  /// **'Female Workers'**
  String get femaleWorkers;

  /// No description provided for @priceMale.
  ///
  /// In en, this message translates to:
  /// **'Price/Male (₹)'**
  String get priceMale;

  /// No description provided for @priceFemale.
  ///
  /// In en, this message translates to:
  /// **'Price/Female (₹)'**
  String get priceFemale;

  /// No description provided for @dailyWage.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage'**
  String get dailyWage;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetails;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @vehicleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mahindra Bolero Pickup'**
  String get vehicleNameHint;

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number (Optional/Private)'**
  String get vehicleNumber;

  /// No description provided for @loadCapacity.
  ///
  /// In en, this message translates to:
  /// **'Load Capacity'**
  String get loadCapacity;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service Area'**
  String get serviceArea;

  /// No description provided for @pricingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Availability'**
  String get pricingAvailability;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (No hidden charges)'**
  String get priceLabel;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @providerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Services'**
  String get providerNameHint;

  /// No description provided for @equipmentUsed.
  ///
  /// In en, this message translates to:
  /// **'Equipment Used'**
  String get equipmentUsed;

  /// No description provided for @equipmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Equipment Info'**
  String get equipmentInfo;

  /// No description provided for @ownerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get ownerNameHint;

  /// No description provided for @brandModel.
  ///
  /// In en, this message translates to:
  /// **'Brand & Model'**
  String get brandModel;

  /// No description provided for @yearManufacture.
  ///
  /// In en, this message translates to:
  /// **'Year of Manufacture (Optional)'**
  String get yearManufacture;

  /// No description provided for @rentalPrice.
  ///
  /// In en, this message translates to:
  /// **'Rental Price'**
  String get rentalPrice;

  /// No description provided for @operatorAvailable.
  ///
  /// In en, this message translates to:
  /// **'Operator Available?'**
  String get operatorAvailable;

  /// No description provided for @operatorAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Can you provide a driver/operator?'**
  String get operatorAvailableSubtitle;

  /// No description provided for @listingUploaded.
  ///
  /// In en, this message translates to:
  /// **'Listing uploaded successfully! Pending Approval.'**
  String get listingUploaded;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill required fields'**
  String get fillRequiredFields;

  /// No description provided for @selectSkillError.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one skill'**
  String get selectSkillError;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @chooseMake.
  ///
  /// In en, this message translates to:
  /// **'Choose Make'**
  String get chooseMake;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose Type'**
  String get chooseType;

  /// No description provided for @chooseVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose Vehicle'**
  String get chooseVehicle;

  /// No description provided for @chooseEquipment.
  ///
  /// In en, this message translates to:
  /// **'Choose Equipment'**
  String get chooseEquipment;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
