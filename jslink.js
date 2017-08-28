var cssId = 'myCss';
if (!document.getElementById(cssId)) {
    var head = document.getElementsByTagName('head')[0];
    var link = document.createElement('link');
    link.id = cssId;
    link.rel = 'stylesheet';
    link.type = 'text/css';
    link.href = 'http://portal/SiteAssets/plugins/DataTables/jquery.dataTables.min.css';
    link.media = 'all';
    head.appendChild(link);
}

if(!window.jQuery) {
    var script = document.createElement('script');
    script.type = "text/javascript";
    script.src = "http://portal/SiteAssets/js/jquery-3.2.1.min.js";
    document.getElementsByTagName('head')[0].appendChild(script);
}

var x = document.createElement('script');
x.src = 'http://portal/SiteAssets/plugins/DataTables/jquery.dataTables.min.js';
document.getElementsByTagName("head")[0].appendChild(x);


(function () {
    var overrideCtx = {};
    overrideCtx.Templates = {}
    overrideCtx.Templates.Header = "<table id='example' class='display' width='100%' cellspacing='0'><thead><tr><th>Ad Soyad</th><th>Ünvan</th><th>Bölüm</th><th>Telefon</th></tr></thead><tfoot><tr><th>Ad Soyad</th><th>Ünvan</th><th>Bölüm</th><th>Telefon</th></tr></tfoot>";                   
    overrideCtx.Templates.Item = dataTemplate;     
    overrideCtx.Templates.Footer = "</table>"; 
    overrideCtx.OnPostRender = dataTableOnPostRender;         

    SPClientTemplates.TemplateManager.RegisterTemplateOverrides(overrideCtx);

})();

function dataTemplate(ctx) { 
    return "<tr><td>"+ ctx.CurrentItem.Title +"</td><td>"+ ctx.CurrentItem.Job_x0020_Title +"</td><td>"+ ctx.CurrentItem.Department +"</td><td>"+ ctx.CurrentItem.Phone+"</td></tr>"; 
}

function dataTableOnPostRender() {
    $(document).ready(function () {
        $('#example').DataTable();
    });
}