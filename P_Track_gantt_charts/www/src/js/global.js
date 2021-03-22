function changeLogo() {

    let l_client ='&G_CLIENT_LOGO.';
    console.log('Client Logo is '+ l_client);
  
    switch(l_client) {
        case 'Provident':
            console.log('Provident logo is in use now');
            apex.jQuery( ".apex-logo-img" ).html(
                apex.util.applyTemplate(
                    "<img src='&IMAGE_PREFIX.logo_big/provident.png'>" ) );
            break;
        case 'Green Contracting':
            console.log('Green Contracting logo is in use now');
            apex.jQuery( ".apex-logo-img" ).html(
                apex.util.applyTemplate(
                    "<img src='&IMAGE_PREFIX.logo_big/green_contracting.jpg'>" ) );
            break;
        case 'AAA Properties':
            console.log('AAA Properties logo is in use now');
            apex.jQuery( ".apex-logo-img" ).html(
                apex.util.applyTemplate(
                    "<img src='&IMAGE_PREFIX.logo_big/aaa_properties.jpg'>" ) );
            break;
        default:
            console.log('Default logo is in use now');
            apex.jQuery( ".apex-logo-img" ).html(
                apex.util.applyTemplate(
                    "<img src='&IMAGE_PREFIX.logo_big/provident.png'>" ) );
    }
}

window.onload = changeLogo;