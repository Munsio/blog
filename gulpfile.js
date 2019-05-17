const autoprefixer = require('gulp-autoprefixer');
const CleanCSS = require('clean-css');
const declassify = require('declassify');
const gulp = require('gulp');
const sass = require('gulp-sass');
const del = require('del');
const path = require('path');
const htmlmin = require('gulp-htmlmin');
const transform = require('gulp-transform');
const inline = require('gulp-inline-source');
const sourcemaps = require('gulp-sourcemaps');
const uncss = require('uncss');


const publicDirectory = 'public';
const srcDirectory = 'themes/munsio/src/';
const stylesDestDirectory = 'static/css';
const stylesSrcDirectory = path.join(srcDirectory, 'scss/**/*.scss');
const htmlPath = path.join(publicDirectory, '**/*.html');
const declassifyOptions = {
  attrs: [`class`],
  ignore: [
    `codepen`,
    /fa.+/,
    /language-.+/, 
    (process.env.NODE_ENV === `test` ? /qa-.+/ : undefined)
  ],
}

gulp.task('clean:styles', function () { return del(stylesDestDirectory) });

gulp.task('styles', function() {
  return gulp.src(stylesSrcDirectory)
    .pipe(sourcemaps.init())
      .pipe(sass().on('error', sass.logError))
      .pipe(autoprefixer())
    .pipe(sourcemaps.write({ sourceRoot: '/scss' }))
    .pipe(gulp.dest(stylesDestDirectory))
});

// gulp.task(`minify:markup`, function() {
//   return gulp.src(htmlPath)
//     .pipe(htmlmin({ collapseWhitespace: true }))
//     .pipe(inline({
//       rootpath: 'static/',
//       handlers: (source, context, next) => {
//         if (source.type === `css` && source.fileContent && !source.content) {
//           uncss(context.html, { htmlroot: 'static/' }, (error, css) => {
//             if (error) throw error;
//             // eslint-disable-next-line no-param-reassign
//             source.content = `<style>${new CleanCSS({ level: 2 }).minify(css).styles}</style>`;
//             next();
//           });
//         } else {
//           next();
//         }
//       },
//     }))
//     .pipe(transform(`utf8`, content => declassify.process(content, declassifyOptions)))
//     .pipe(gulp.dest(publicDirectory))
// });

const compileStyles = gulp.series('clean:styles', 'styles');
const build = gulp.series('clean:styles', 'styles');

module.exports = { build: build }

gulp.task('watch', () => {
    gulp.watch(stylesSrcDirectory, compileStyles);
  });

gulp.task('default', gulp.parallel('watch', build));