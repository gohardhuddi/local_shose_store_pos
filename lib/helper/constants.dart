import 'dart:ui';

class CustomImagesPaths {
  static const shoeBlackIcon = "assets/images/shoe_black_icon.png";
  static const shoeWhiteIcon = "assets/images/shoe_white_icon.png";
  static const sliderImage3 = "assets/images/carisol_image_3.png";
  static const facebookIcon = "assets/images/facebook_icon.png";
  static const googleIcon = "assets/images/google_icon.png";
  static const emailIcon = "assets/images/email_icon.png";
  static const appIcon = "assets/images/appIcon.png";
  static const cartIcon = "assets/images/cart.png";
  static const video = "assets/images/Splash.mp4";
  static const cloudServiceIcon = "assets/images/cloud-service.png";
  static const internetIcon = "assets/images/internet.png";
  static const connectivityStateIcon = "assets/images/responsive.png";
}

class CustomStrings {
  static const shopName = "Anarkali Shoes";
  static const totalQuantity = "Total Stock Quantity";
  static const totalPrice = "Total Stock Value Price";
  static const saleScreenHeading = "Anarkali Shoes POS";
  static const cartScreenHeading = "Anarkali Shoes Cart";
  static const inventoryManagementSystem = "Inventory Management System";
  static const salesRecord = "Sales Record";
  static const returnSale = "Return Sales";

  // Navigation
  static const sale = "Sale";
  static const stock = "Stock";
  static const returnText = "Return";
  static const more = "More";
  static const settings = "Settings";
  static const homePage = "Home Page";
  static const profilePage = "Profile Page";

  // Add Stock Screen
  static const addStock = "Add Stock";
  static const product = "Product";
  static const variant = "Variant";
  static const brand = "Brand *";
  static const brandHint = "e.g Bata Shoes";
  static const articleCode = "Article Code *";
  static const articleCodeHint = "e.g ADSH001";
  static const articleName = "Article Name";
  static const articleNameHint = "e.g Adidas Runner";
  static const size = "Size *";
  static const sizeHint = "e.g 48";
  static const color = "Color";
  static const colorHint = "e.g Black";
  static const productCodeSku = "Product Code SKU *";
  static const productCodeSkuHint = "e.g ADSH001-BLK-42";
  static const quantity = "Quantity *";
  static const quantityHint = "e.g 10";
  static const purchasePrice = "Purchase Price *";
  static const purchasePriceHint = "e.g 700";
  static const suggestedSalePrice = "Suggested Sale Price *";
  static const suggestedSalePriceHint = "e.g 1000";

  // Edit Stock Screen
  static const updateVariant = "Update Variant";
  static const updateStock = "Update Stock";
  static const action = "Action";
  static const add = "Add";
  static const subtract = "Subtract";

  // View Stock Screen
  static const stockTitle = "Stocks";
  static const searchHint = "Search brand, article, SKU, color, size…";
  static const noStockYet = "No stock yet. Add some!";
  static const noStock = "No stock";
  static const addStockButton = "Add Stock";
  static const viewCartButton = "View Cart";
  static const confirmDelete = "Confirm Delete";
  static const confirmDeleteMessage = "Are you sure you want to delete this?";
  static const cancel = "Cancel";
  static const delete = "Delete";
  static const edit = "Edit";
  static const tapped = "Tapped";
  static const price = "price";
  static const lineTotal = "Line Total";
  static const noSales = "No sales recorded yet.";

  // Colors
  static const black = "Black";
  static const brown = "Brown";
  static const white = "White";
  static const red = "Red";
  static const blue = "Blue";
  static const other = "Other";

  // Validation Messages
  static const colorRequired = "Color is required";
  static const actionRequired = "Action is required";
  static const quantityGreaterThanZero = "Quantity should be greater then 0";
  static const priceGreaterThanZero = "Price should be greater then 0";
  static const salePriceGreaterThanPurchase =
      "Sale Price should be equal or greater then Purchase Price";
  static const fieldRequired = "is required";

  // Display Text
  static const sku = "SKU:";
  static const sizeLabel = "Size:";
  static const colorLabel = "Color:";
  static const qty = "Qty:";
  static const buy = "Buy:";
  static const sell = "Sell:";
  static const qtyTotal = "Qty";
  static const variants = "Variants";
  static const salesHistory = "Sales History";
  static const searchByDate = "Search by SKU, Amount, or Date (DD-MM-YYY)";
  static const saleID = "Sale ID:";
  static const total = "Total:";
  static const currency = "Rs";

  // Success/Error Messages
  static const stockAddedSuccessfully = "Stock Added Successfully";
  static const productSyncedSuccessfully = "Products Synced Successfully";
  static const productSyncedError = "Products Sync Error";
  static const variantDeletedSuccessfully = "Variant Deleted Successfully";
  static const movementAddedSuccessfully = "Movement Added Successfully";
  static const itemAddedToCartSuccessfully = "Item Added to Cart Successfully";
  static const somethingWentWrong = "Something went wrong! Try Again";

  // Legacy strings (keeping for compatibility)
  static const theAppForSportsCommunity = "The app for the sports community ";
  static const continueWithFacebook = "Continue with Facebook";
  static const continueWithGoogle = "Continue with Google";
  static const signupWithEmail = "Signup with email";
  static const alreadyHaveAnAccount = "Already have an account ?";
  static const login = "Login";
  static const createAccount = "Create account";
  static const resetPassword = "Reset Password";
  static const emailAddress = "E-mail address";
  static const firstName = "First name";
  static const lastName = "Last name";
  static const password = "Password";
  static const newPassword = "New Password";
  static const confirmPassword = "Confirm password";
  static const confirmNewPassword = "Confirm new password";
  static const phoneNumber = "Phone number ";
  static const consent = "Consent";
  static const byClickingBox =
      "By checking this box & using our application you hereby consent to our disclaimer and agree to our terms & policies.";
  static const iAgree = "I agree";
  static const confirmAccount = "Confirm Account";
  static const createProfile = "Create Profile";
  static const userName = "Username";
  static const dateOfBirth = "Date of birth";
  static const selectGender = "Select Gender";
  static const fitnessLevel = "Fitness Level";
  static const doYouHaveAnyDisability = "Do you have any disability?";
  static const next = "Next";
  static const tellUsAboutYou = "Tell us about you";
  static const aboutMe = "About Me";
  static const enterShortDescriptionOfYourself =
      "Enter a short description of yourself";
  static const choseATitleThatBest = "Choose the TITLE that best describe you!";
  static const interests = "Interests";
  static const travel = "Travel";
  static const dance = "Dance";
  static const fitness = "Fitness";
  static const reading = "Reading";
  static const photography = "Photography";
  static const music = "Music";
  static const movie = "Movie";
  static const all = "All";
  static const nutrition = "Nutrition";
  static const fashion = "Fashion";
  static const equipments = "Equipments";
  static const searchSport = "Search sport:";
  static const gyms = "Gyms";
  static const confirm = "Confirm";
  static const selectAtLeast4Activities =
      "Select At Least 4 Activities\n To Get Started";
  static const forgotPassword = "Forgot Password";
  static const pleaseEnterEmail =
      "Please enter the email address you use to create your account confirmation link will be sent to you shortly";

  static String dbname = 'shoe_pos_floor.db';
}

class CustomColors {
  static const redButtonColor = Color(0xffD21034);
  static const blueColor = Color(0xff1777F2);
  static Color whiteButtonColors = Color(0xffFFFFFF);
  static Color blackColors = Color(0xff000000);
  static Color greyColors = Color(0xff8C96A2);
  static Color darkblueColors = Color(0xff293088);
  static Color greenColors = Color(0xff1FCC79);
  static Color lightGreyColors = Color(0xffE3E1E1);
  List<List<Color>> chipsColors = [
    [Color(0xffFFE9E6), Color(0xffFF6F59)],
    [Color(0xffE5F7FF), Color(0xff33C0FF)],
    [Color(0xffFFF2E5), Color(0xffFF9933)],
    [Color(0xff5985FF), Color(0xffE5ECFF)],
    [Color(0xff9933FF), Color(0xffF2E5FF)],
    [Color(0xff12B2B2), Color(0xffE0FFFF)],
    [Color(0xffFFE5EE), Color(0xffFF3377)],
  ];
}
